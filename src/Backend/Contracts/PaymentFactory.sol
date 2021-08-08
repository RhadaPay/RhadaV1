// SPDX-License-Identifier: MIT

pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/** TO DO:
 * Check states
 * Withdrawing funds
 * Mediation
 * Fix up require statements
 * Loan idea
 * Integrate contracts
 * Complete all events
 **/ 

contract PaymentFactory {
    /**
     * States a job can be in which limits the amount of methods one can call per job
     * Open: Applicants may apply, the job creator can alter the variables for a job, and the job creator can choose an applicant
     * Signing: The job creator can no longer change the variables, applicants can no longer apply, the job creator may withdraw
     *          from the deal, the job creator stakes during his signing, the applicant agrees to the set terms before he or she was chosen
     * Signed: The applicant may submit his or her work
     * Closed: The job creator and the chosen applicant sign off on the final work, creating the payment stream and beginning the event tracker
     **/ 
    enum State {Open, Signing, Signed, Closed}

    struct EventStream {
        string descriptor;
        string[] cid;
    }

    struct Job {
        address creator;
        uint amount;
        uint refreshRate;
        uint eventStreamId;
        uint eventsRecorded;
        bool creatorSigned;
        bool applicantSigned;
        bool workSubmitted;
        State state;
    }
    
    // Mappings
    mapping(uint => address[]) public jobToApplicants;
    mapping(uint => address) public finalApplicant;
    
    // Arrays
    Job[] public jobs;
    EventStream[] public eventStreams;
    
    // Events
    event JobCreated(address creator, uint initAmount, uint refreshRate, uint jobID, uint eventStreamId);
    event EventStreamCreated(string descriptor, uint streamID);
    event AmountChanged(uint amount, uint jobID);
    event ApplicantApplied(address applicant, uint jobID);
    event ApplicantChosen(address applicant, uint jobID);
    event ApplicantSigned(address applicant, uint jobID);
    event CreatorSigned(address creator, uint jobID);
    event JobCompleted(uint jobID);
    event FinalSign(address creator, address applicant, uint jobID);
    event FinalResult(address creator, address applicant, uint jobID, bool result);
    event UpdateNumberOfEvents(uint newTotal, uint jobID);

    constructor() {}
    
    // Modifiers
    
    /**
     * @notice Confirms if the sender is the right address
     **/ 
    modifier auth(address src) {
        require(src == msg.sender, "Not authorized");
        _;
    }
    
    /**
     * @notice Confirms if the job is in the correct state
     **/ 
    modifier inState(State _state, uint jobID) {
        require(jobs[jobID].state == _state, "Incorrect state");
        _;
    }

    // Getters
    
    /**
     I needed to add some getters for jobs and eventstreams
     These can't be directly accessed using solidity, however you can retrieve struct internal
     information and so have removed the getters, see the tests for more info.
    **/

    function getJobs() public view returns (Job[] memory) {
        return jobs;
    }

    function getEventStreams() public view returns (EventStream[] memory) {
        return eventStreams;
    }

    // Public functions
    
    /**
     * @notice A new job is created with the terms set by the job creator
     * @dev Look into mediation and whether or not names/descs should be held in the backend
     * @param _initAmount The initial amount that is staked by the job creator
     * @param _refreshRate Number of events before triggering a payment refresh
     * @param _eventStreamId connect a job to an event stream
     **/
    function createJob(uint _initAmount, uint _refreshRate, uint _eventStreamId) public  {
        require(_eventStreamId + 1 <= eventStreams.length, "Event Stream does not exist");
        jobs.push(Job({
            creator: msg.sender,
            amount: _initAmount,
            refreshRate: _refreshRate,
            eventsRecorded: 0,
            eventStreamId: _eventStreamId,
            creatorSigned: false,
            applicantSigned: false,
            workSubmitted: false,
            state: State.Open
        }));
        uint jobID = jobs.length - 1;
        emit JobCreated(msg.sender, _initAmount, _refreshRate, jobID, _eventStreamId);
    }

    /**
     * @notice Creates a new event stream
     * @dev Check
     * @param _descriptor A generic description of the event stream
    **/
    function createEventStream(string memory _descriptor) public {
        EventStream memory es;
        es.descriptor = _descriptor;
        eventStreams.push(es);
        uint streamID = eventStreams.length - 1;
        emit EventStreamCreated(_descriptor, streamID);
    }
    
    /**
     * @notice The job creator can configure the down payment before finalizing his choice of applicant
     * @dev downpayment will be confirmed during the signing process
     * @param newAmount The new down payment
     * @param jobID The ID of a specific job
     **/
    function configureAmount(uint newAmount, uint jobID) public auth(jobs[jobID].creator) inState(State.Open, jobID) {
        require(newAmount > 0);
        jobs[jobID].amount = newAmount;
        // Emit events
    }

    /**
     * @notice Configure the refresh rate while the applicant hasn't been chosen
     * @dev States/logic check
     * @param newRefreshRate The new number of events before a payment refresh is triggered
     * @param jobID The ID of a specific job
    **/
    function changeRefreshRate(uint8 newRefreshRate, uint jobID) public auth(jobs[jobID].creator) inState(State.Open, jobID) {
        require(newRefreshRate > 0, "Refresh rate needs to be greater than 0.");
        jobs[jobID].refreshRate = newRefreshRate;
    }

    /**
     * @notice Applicants apply for a specific job
     * @dev Can flesh out a little bit more, but this is probably ok for now
     * @param jobID The ID of a specific job
     **/ 
    function applyForJob(uint jobID) public inState(State.Open, jobID) {
        jobToApplicants[jobID].push(msg.sender);
        emit ApplicantApplied(msg.sender, jobID);
    }
    
    /**
     * @notice The job creator can choose an applicant for his job
     * @dev Need to flesh out a little... Give applicant the choice to still choose the job before money is staked (do in signing process)
     * @dev For the above, make sure the states are worked out
     * @param chosenApplicant The applicant who is accepted
     * @param jobID The ID of a specific job
     **/ 
    function chooseApplicant(address chosenApplicant, uint jobID) public auth(jobs[jobID].creator) inState(State.Open, jobID) {
        finalApplicant[jobID] = chosenApplicant;
        jobs[jobID].state = State.Signing;
        emit ApplicantChosen(chosenApplicant, jobID);
    }
    
    /**
     * @notice The applicant signs off and agrees to do a job. The applicant can still withdraw from the commitment before the creator also signs off
     * @dev Add init stake to prevent bailing? May be a deterrent...
     * @param jobID The ID of a specific job
     **/ 
    function initApplicantSign(uint jobID) public auth(finalApplicant[jobID]) inState(State.Signing, jobID) {
        jobs[jobID].applicantSigned = true;
        emit ApplicantSigned(msg.sender, jobID);
    }
    
    /**
     * @notice The creator officially signs off and the job process starts
     * @dev Check the states
     * @param jobID The ID of a specific job
     **/ 
    function initCreatorSign(uint jobID) public payable auth(jobs[jobID].creator) inState(State.Signing, jobID) {
        uint val = msg.value;
        require(jobs[jobID].amount >= val);
        jobs[jobID].state = State.Signed;
        jobs[jobID].amount = val;
        jobs[jobID].creatorSigned = true;
        emit CreatorSigned(msg.sender, jobID);
    }
    
    /**
     * @notice Signals that work is submitted. Acts as the applicant signing
     * @dev Check states. Probably need a bool for simple storage. Should emphasize 
     *      communicating with the job creator before submission
     * @dev Implement states and refusals
     * @param jobID The ID of a specific job
     **/ 
    function submitWork(uint jobID) public auth(finalApplicant[jobID]) inState(State.Signed, jobID) {
        jobs[jobID].workSubmitted = true; 
    }
    
    /**
     * @notice The job creators final sign off. Signals event tracking and the payment stream
     * @dev Include ability to refuse? Who would pay gas to refuse? Just don't pay...
     * @dev In response to above comment: could be where mediation comes in. Mediator checks work, then decides who receives stake?
     * @dev Would need to emphasize a high initAmount in that case
     * @param result Dictates whether the work is accepted or rejected. True to accept, false to reject
     * @param jobID The ID of a specific job
     **/
    function finalSign(bool result, uint jobID) public auth(jobs[jobID].creator) {
        require(jobs[jobID].workSubmitted == true);
        jobs[jobID].state = State.Closed;
        if(result) {
            // Begin payment stream + events
        } else if(!result) {
            // Mediation? Receive stake back after mediation?
        }
        emit FinalResult(msg.sender, finalApplicant[jobID], jobID, result);
    }
}
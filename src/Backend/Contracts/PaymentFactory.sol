// SPDX-License-Identifier: MIT

pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/** TO DO:
 * Check states
 * Withdrawing funds
 * Mediation
 * Implement loan idea. Also flesh out and discuss it more. Implement a function where creator can only increase his holdings
 *              Hard to do w/o someone (the seller) being punished
 * Implement the streampay
 * Clean up code + comments
 * Add a stake for the worker to make up for gas fees if bails on job? Does this act as more of a deterrent though?
 * Begin testing
 * Add require statements + messages w/ require statements
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

    /** For @jordaniza
     * I merged the two contracts to save on gas and make it neater
     * I organized the structs so that the job would only have job-related
     *      items and that the EventStream would only have items related to that.
     *       I thought that it helped w/ organization and clarity. It also allows us
     *       to not have to keep track of an EventStream ID and to easily interact
     *       with the EventStream functions separately 
     * Storage is very important so I changed uints to uint8, uint16, etc. In solidity:
     *     outside of a struct, uints are always allocated as uint256s regardless of what you put them as.
     *     Inside of a struct however, if you declare uints all next to each other, the storage is merged.
     *      So, rather than wasting storage + increasing gas costs, we can reduce the allocation while
     *      ensuring that the numbers inputted will never logically go over the number of bytes limited by the integer
     *
     *
    **/


    /** EventStream:
     * An EventStream exists independently of Jobs and exists to group Real-World Events
     * Every time we want to start capturing a new sequence of events, we instantiate a new event stream
     * Jobs can be connected to event streams by referencing the stream ID
     * Individual events are not stored on the blockchain, but instead can be viewed in IPFS
    **/ 
    struct EventStream {
        string[] batches;
        uint8 refreshCadence;
    }

    struct Job {
        address creator;
        uint amount;
        bool creatorSigned;
        bool applicantSigned;
        bool workSubmitted;
        EventStream eventStream;
        State state;
    }

    // Mappings
    mapping(uint => address[]) public jobToApplicants;
    mapping(uint => address) public finalApplicant;
    
    // Arrays
    Job[] public jobs;
    EventStream[] public eventStreams;
    
    // Events
    event JobCreated(address creator, uint initAmount, uint jobID);
    event EventStreamCreated(string[] batches, uint8 refreshCadence);
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
        
    // Public functions
    /**
     * @notice Creates a specific event stream
     * @dev Need a create batch function
     * @dev Should it be a string array or a bytes/bytes32 array?
     * @param _batches List of event batches
     * @param _refreshCadence Number of events before triggering a payment refresh
    **/
    function _createEventStream(string[] memory _batches, uint8 _refreshCadence) private returns(EventStream memory) {
        emit EventStreamCreated(_batches, _refreshCadence);
        return EventStream({
            batches: _batches,
            refreshCadence: _refreshCadence
            });
        
    }
    
    /**
     * @notice A new job is created with the terms set by the job creator
     * @dev Look into mediation and whether or not names/descs should be held in the backend
     * @param _initAmount The initial amount that is staked by the job creator
     **/
    function createJob(uint _initAmount, string[] memory _batches, uint8 _refreshCadence) public {
        jobs.push(Job({
            creator: msg.sender,
            amount: _initAmount,
            creatorSigned: false,
            applicantSigned: false,
            workSubmitted: false,
            eventStream: _createEventStream(_batches, _refreshCadence),
            state: State.Open
        }));
        uint jobID = jobs.length - 1;
        emit JobCreated(msg.sender, _initAmount, jobID);
    }

    // Maybe allow adding of batches in any state? Does leave open to possible errors
    function addBatch(string memory batchHash, uint jobID) public auth(jobs[jobID].creator) inState(State.Open, jobID) {
        
    }

    function changeRefreshRate(uint8 newRefreshCadence, uint jobID) public auth(jobs[jobID].creator) inState(State.Open, jobID) {
        require(newRefreshCadence > 0, "Refresh rate needs to be greater than 0.");
        (jobs[jobID].eventStream).refreshCadence = newRefreshCadence;
    }
    
    /**
     * notice The job creator can configure the down payment before finalizing his choice of applicant
     * dev downpayment will be confirmed during the signing process
     * param newAmount The new down payment
     * param jobID The ID of a specific job
     **/
    function configureAmount(uint newAmount, uint jobID) public auth(jobs[jobID].creator) inState(State.Open, jobID) {
        require(newAmount > 0);
        jobs[jobID].amount = newAmount;
        // Emit events
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
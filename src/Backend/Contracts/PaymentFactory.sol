// SPDX-License-Identifier: MIT

pragma solidity ^0.7.1;

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
     * Completed: The work is submitted
     * Closed: The job creator and the chosen applicant sign off on the final work, creating the payment stream and beginning the event tracker
     **/ 
    enum State {Open, Signing, Signed, Completed, Closed}
    
    struct Job {
        address creator;
        uint amount;
        State state;
        bool creatorSigned;
        bool applicantSigned;
        bool workSubmitted;

        // additional linkages to an eventStream
        uint eventStreamId;
        uint numberOfEvents;
    }
    
    // Mappings
    mapping(uint => address[]) public jobToApplicants;
    mapping(uint => address) public finalApplicant;
    
    // Arrays
    Job[] public jobs;
    
    // Events
    event JobCreated(address creator, uint initAmount, uint jobID);
    event DownpaymentChanged();
    event ApplicantApplied(address applicant, uint jobID);
    event ApplicantChosen(address applicant, uint jobID);
    event ApplicantSigned(address applicant, uint jobID);
    event CreatorSigned(address creator, uint jobID);
    event JobCompleted(uint jobID);
    event FinalSign(address creator, address applicant, uint jobID);
    event FinalResult(address creator, address applicant, uint jobID, bool law);

    event UpdateNumberOfEvents(uint jobId, uint eventStreamId, uint newTotal);

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
     * @notice A new job is created with the terms set by the job creator
     * @dev Look into mediation and whether or not names/descs should be held in the backend
     * @param _initAmount The initial amount that is staked by the job creator
     **/
    function createJob(uint _initAmount, uint _eventStreamId) public {
        jobs.push(Job({
            creator: msg.sender,
            amount: _initAmount,
            state: State.Open,
            creatorSigned: false,
            applicantSigned: false,
            workSubmitted: false,

            eventStreamId: _eventStreamId,
            numberOfEvents: 0
        }));
        uint jobID = jobs.length - 1;
        emit JobCreated(msg.sender, _initAmount, jobID);
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
     * @param law Dictates whether the work is accepted or rejected. True to accept, false to reject
     * @param jobID The ID of a specific job
     **/
    function finalSign(bool law, uint jobID) public auth(jobs[jobID].creator) {
        require(jobs[jobID].workSubmitted == true);
        jobs[jobID].state = State.Closed;
        if(law) {
            // Begin payment stream + events
        } else if(!law) {
            // Mediation? Receive stake back after mediation?
        }
        emit FinalResult(msg.sender, finalApplicant[jobID], jobID, law);
    }

    function updateNumberOfEvents(uint jobId, uint newTotal) public {
        Jobs[jobID].numberOfEvents = newTotal;
        emit UpdateNumberOfEvents(jobId, Jobs[jobId].eventStreamId, newTotal);
    }
}

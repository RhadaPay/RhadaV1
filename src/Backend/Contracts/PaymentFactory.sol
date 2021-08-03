// SPDX-License-Identifier: MIT

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

pragma solidity ^0.8.0;

/** TO DO:
 * Check states
 * Check the logic behind withdrawing funds after certain amount of time
 * Implement "loan" idea
 * Implement the streampay
 * Clean up code + comments
 * Fix the stake ether function. Remove and put elsewhere
 * Put more withdrawal functions in case
 * Add a stake for the worker to make up for gas fees if bails on job? Does this act as more of a deterrent though?
 * Begin testing
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
        uint downPayment;
        uint incrementPay;
        uint timeBeforeStakeRemoved;
        State state;
        bool creatorSigned;
        bool applicantSigned;
    }
    
    // Mappings
    mapping(uint => address[]) jobToApplicants;
    mapping(uint => address) finalApplicant;
    
    // Arrays
    Job[] jobs;
    
    // Events
    event JobCreated(address creator, uint downPayment, uint incrementPay, uint timeBeforeStakeRemoved, uint jobID);
    event DownpaymentChanged();
    event ApplicantApplied(address applicant, uint jobID);
    event ApplicantChosen(address applicant, uint jobID);
    event ApplicantSigned(uint jobID, address applicant);
    event CreatorSigned(uint jobID, address creator);
    event JobCompleted(uint jobID);
    event FinalSign(address creator, address applicant, uint jobID);
    event StakeRemoved(address creator, uint amount, uint jobID);
    
    constructor() {}
    
    // Modifiers
    
    /**
     * @notice Confirms whether the address is the creator of the given job
     * @dev Can probably remove this one and just merge it with auth for more flexibility
     **/
    modifier isCreator(address src, uint jobID) {
        require(src == jobs[jobID].creator);
        _;
    }
    
    /**
     * @notice Confirms if the sender is the right address
     **/ 
    modifier auth(address src) {
        require(src == msg.sender);
        _;
    }
    
    /**
     * @notice Confirms if the job is in the correct state
     **/ 
    modifier isState(State _state, uint jobID) {
        require(jobs[jobID].state == _state);
        _;
    }
    
    
    // Private functions
    
    function _signalExternal() private {
        
    }
    
    function _createPaymentStream() private {
        
    }
    
    
    // Public functions
    
    /**
     * @notice Ether is staked by the creator for the job.
     * @dev This function is most likely not logically written. Staking should be done inside the signing method
     **/ 
    function stakeEther(uint jobID) public payable isCreator(msg.sender, jobID) {
        require(msg.value >= jobs[jobID].downPayment);
    }
    
    /**
     * @notice A new job is created with the terms set by the job creator
     * @dev Some variables may be unneeded, such as the creator signing var
     * @dev look into incrementPay
     * @dev Look into timeBeforeStakeRemoved
     * @param _downPayment The initial downpayment that is staked by the job creator
     * @param _incrementPay The initial increment per event (more on this... probably an oracle is the right way to go about this param. Could also standardize it)
     * @param _timeBeforeStakeRemoved The time before the job creator can remove his stake after the job is submitted
     **/ 
    function createJob(uint _downPayment, uint _incrementPay, uint _timeBeforeStakeRemoved) public payable {
        jobs.push(Job({
            creator: msg.sender,
            downPayment: _downPayment,
            incrementPay: _incrementPay,
            timeBeforeStakeRemoved: _timeBeforeStakeRemoved + block.timestamp,
            state: State.Open,
            creatorSigned: false,
            applicantSigned: false
        }));
        uint jobID = jobs.length - 1;
        emit JobCreated(msg.sender, _downPayment, _incrementPay, _timeBeforeStakeRemoved, jobID);
    }
    
    /**
     * @notice The job creator can configure the down payment before finalizing his choice of applicant
     * @dev downpayment will be confirmed during the signing process
     * @param newDownPayment The new down payment
     * @param jobID The ID of a specific job
     **/ 
    function configureJobDownPayment(uint newDownPayment, uint jobID) public isCreator(msg.sender, jobID) isState(State.Open, jobID) {
        jobs[jobID].downPayment = newDownPayment;
        
    }
    
    /**
     * @notice Applicants apply for a specific job
     * @dev Can flesh out a little bit more, but this is probably ok for now
     * @param jobID The ID of a specific job
     **/ 
    function applyForJob(uint jobID) public {
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
    function chooseApplicant(address chosenApplicant, uint jobID) public isCreator(msg.sender, jobID) {
        finalApplicant[jobID] = chosenApplicant;
    }
    
    /**
     * @notice The applicant signs off and agrees to do a job. The applicant can still withdraw from the commitment before the creator also signs off
     * @dev Make sure states make sense. Add a function to withdraw
     * @param jobID The ID of a specific job
     **/ 
    function initApplicantSign(uint jobID) public {
        
    }
    
    /**
     * @notice The creator officially signs off and the job process starts
     * @dev Check the states
     * @param jobID The ID of a specific job
     **/ 
    function initCreatorSign(uint jobID) public isCreator(msg.sender, jobID) {
        
    }
    
    /**
     * @notice Signals that work is submitted. Acts as the applicant signing
     * @dev Check states. Probably need a bool for simple storage. Should emphasize 
     *      communicating with the job creator before submission
     * @dev Implement states and refusals
     * @param jobID The ID of a specific job
     **/ 
    function submitWork(uint jobID) public auth(finalApplicant[jobID]){
        
    }
    
    /**
     * @notice The job creators final sign off. Signals event tracking and the payment stream
     * @dev Refusals and states
     * @param jobID The ID of a specific job
     **/
    function finalSign(uint jobID) public isCreator(msg.sender, jobID) isState(State.Completed, jobID) {
        
    }
    
    /**
     * @notice The job creator can remove his stake after the allotted time
     * @dev Need to discuss this idea more. Worker should be guaranteed some pay + extra as an investment
     * @param jobID The ID of a specific job
     **/ 
    function removeStake(uint jobID) public payable isCreator(msg.sender, jobID) {
        if(block.timestamp > jobs[jobID].timeBeforeStakeRemoved) {
            // Need to make sure stream cancels
            // Also need to implement remaining funds tracker
            (payable(jobs[jobID].creator)).transfer(jobs[jobID].downPayment);
            emit StakeRemoved(msg.sender, jobs[jobID].downPayment, jobID);
        }
    }
    
}

// SPDX-License-Identifier: MIT

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

pragma solidity ^0.8.0;

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
    
    /**
     * @notice Confirms whether the address is the creator of the given job
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
    
    /**
     * @dev Probably an unecessary function
     **/ 
    function _sign() private {
        
    }
    
    /**
     * @notice Ether is staked by the creator for the job.
     * @dev This function is most likely not logically written. Staking should be done inside the signing method
     **/ 
    function stakeEther(uint jobID) public payable isCreator(msg.sender, jobID) {
        require(msg.value >= jobs[jobID].downPayment);
    }
    
    function _signalExternal() private {
        
    }
    
    function _createPaymentStream() private {
        
    }
    
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
     * @dev downpayment will be confirmed during the signing process
     **/ 
    function configureJobDownPayment(uint _downPayment, uint jobID) public isCreator(msg.sender, jobID) isState(State.Open, jobID) {
        jobs[jobID].downPayment = _downPayment;
        
    }
    
    function applyForJob(uint jobID) public {
        jobToApplicants[jobID].push(msg.sender);
        emit ApplicantApplied(msg.sender, jobID);
    }
    
    function chooseApplicant(address chosenApplicant, uint jobID) public isCreator(msg.sender, jobID) {
        finalApplicant[jobID] = chosenApplicant;
    }
    
    function initApplicantSign() public {
        
    }
    
    function submitWork() public {
        
    }
    
    function finalSign() public {
        
    }
    
    function removeStake(uint jobID) public payable isCreator(msg.sender, jobID) {
        if(block.timestamp > jobs[jobID].timeBeforeStakeRemoved) {
            // Need to make sure stream cancels
            // Also need to implement remaining funds tracker
            (payable(jobs[jobID].creator)).transfer(jobs[jobID].downPayment);
            emit StakeRemoved(msg.sender, jobs[jobID].downPayment, jobID);
        }
    }
    
}

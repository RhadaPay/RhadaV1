// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PaymentFactory {
    enum State {Open, Signed, Completed, Closed}
    
    struct Job {
        address creator;
        //Applicant[] applicants;
        uint downPayment;
        uint incrementPay;
        State state;
    }
    
    struct Applicant {
        address applicant;
        
    }
    
    Job[] jobs;
    
    // Events
    event JobCreated(address creator, uint downPayment, uint incrementPay, uint jobID);
    event ApplicantApplied(address applicant, uint jobID);
    event ApplicantChosen(address applicant, uint jobID);
    event JobSigned(uint jobID, address creator, address applicant);
    event JobCompleted(uint jobID);
    event FinalSign(address creator, address applicant, uint jobID);
    
    constructor() {}
    
    modifier isCreator(address src, uint jobID) {
        require(src == jobs[jobID].creator);
        _;
    }
    
    modifier inState(State _state, uint jobID) {
        require(jobs[jobID].state == _state);
        _;
    }
    
    function _sign() private {
        
    }
    
    function _signalExternal() private {
        
    }
    
    function createJob(uint _downPayment, uint _incrementPay) public payable {
        //Applicant[] memory _applicants;
        jobs.push(Job({
            creator: msg.sender,
            //applicants: _applicants,
            downPayment: _downPayment,
            incrementPay: _incrementPay,
            state: State.Open
        }));
        uint jobID = jobs.length - 1;
        emit JobCreated(msg.sender, _downPayment, _incrementPay, jobID);
    }
    
    function configureJob() public {
        
    }
    
    function applyForJob() public {
        
    }
    
    function chooseApplicant() public {
        
    }
    
    function initSign() public {
        
    }
    
    function submitWork() public {
        
    }
    
    function finalSign() public {
        
    }
    
    
}

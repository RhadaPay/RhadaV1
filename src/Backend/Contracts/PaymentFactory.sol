// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./Cashflow/Interfaces/ITradeableCashflowWithAllowanceFactory.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Utils/Int96SafeMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";



/** TO DO:
 * Check states
 * Withdrawing funds
 * Mediation
 * Fix up require statements
 * Loan idea
 * Integrate contracts
 * Complete all events
 **/

contract PaymentFactory is AccessControl{
    using SafeMath for uint256;
    using Int96SafeMath for int96;

    /**
     * States a job can be in which limits the amount of methods one can call per job
     * Open: Applicants may apply, the job creator can alter the variables for a job, and the job creator can choose an applicant
     * Signing: The job creator can no longer change the variables, applicants can no longer apply, the job creator may withdraw
     *          from the deal, the job creator stakes during his signing, the applicant agrees to the set terms before he or she was chosen
     * Signed: The applicant may submit his or her work
     * Closed: The job creator and the chosen applicant sign off on the final work, creating the payment stream and beginning the event tracker
     **/
    enum State {
        Open,
        Signing,
        Signed,
        Closed
    }

    struct EventStream {
        string descriptor;
        string[] cid;
    }

    struct Job {
        address creator;
        string descriptor;
        uint256 amount;
        uint256 refreshRate;
        uint8 percentage;
        string assetCid;
        uint256 eventStreamId;
        uint256 eventsRecorded;
        bool creatorSigned;
        bool applicantSigned;
        bool workSubmitted;
        State state;
    }

    //ACL
    bytes32 public constant JOB_ORACLE = keccak256("JOB_ORACLE");
    bytes32 public constant JOB_ADMIN = keccak256("JOB_ADMIN");

    address public cashflowFactory;

    // Mappings
    mapping(uint256 => address[]) public jobToApplicants;
    mapping(uint256 => address) public finalApplicant;

    // Arrays
    Job[] public jobs;
    EventStream[] public eventStreams;

    // Events
    event JobCreated(
        address creator,
        uint256 initAmount,
        uint256 refreshRate,
        uint256 jobID,
        uint256 eventStreamId
    );
    event EventStreamCreated(
        string descriptor, 
        uint256 streamID);
    event AmountChanged(
        uint256 amount, 
        uint256 jobID);
    event ApplicantApplied(
        address applicant, 
        uint256 jobID);
    event ApplicantChosen(
        address applicant, 
        uint256 jobID);
    event ApplicantSigned(
        address applicant, 
        uint256 jobID);
    event CreatorSigned(
        address creator, 
        uint256 jobID);
    event JobCompleted(
        uint256 jobID);
    event FinalSign(
        address creator, 
        address applicant, 
        uint256 jobID);
    event FinalResult(
        address creator,
        address applicant,
        uint256 jobID,
        bool result
    );
    event UpdateNumberOfEvents(uint256 newTotal, uint256 jobID);

    constructor(address _cashflowFactory)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(JOB_ADMIN, msg.sender);
        cashflowFactory = _cashflowFactory;
    }

    function updateCashflowFactoryAddress(address _cashflowFactory) isJobAdmin public {
        cashflowFactory = _cashflowFactory;
    }


    // TradeableCashflowWithAllowanceFactory integration
    function _createNewCashflow(
        address recipient,
        address sender,
        uint256 jobId,
        int96 allowedFlow,
        int96 maxAllowedFlow,
        uint256 deadline
    ) internal returns(address) {
        require(cashflowFactory != address(0), "Cashflow Factory address is not set");
        return ITradeableCashflowWithAllowanceFactory(cashflowFactory).createNewCashflow(recipient, sender, jobId, allowedFlow, maxAllowedFlow, deadline);
    }


    /**
     * @notice Increase the cashflow allowance of a job according to a percentage 
     * @dev Can only be called by an address with job oracle role
     * @param jobId The ID of a specific job
     * @param eventsRecorded Number of events recorded to update
     **/
    function increaseCashflowAllowance(uint256 jobId, uint eventsRecorded) isJobOracle public{
        require(cashflowFactory != address(0), "Cashflow Factory address is not set");
        jobs[jobId].eventsRecorded = eventsRecorded;

        ITradeableCashflowWithAllowanceFactory factory = ITradeableCashflowWithAllowanceFactory(cashflowFactory);
        int96 currentFlow = factory.getAllowedFlow(jobId);
        int96 flowIncrease = currentFlow.div(int96(100), "div overflow").mul(int96(jobs[jobId].percentage), "mul overflow");
        factory.updateCashflowAllowance(jobId, currentFlow.add(flowIncrease, "add overflow"));
    }

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
    modifier inState(State _state, uint256 jobID) {
        require(jobs[jobID].state == _state, "Incorrect state");
        _;
    }

    modifier isJobOracle {
        require(hasRole(JOB_ORACLE, msg.sender), "Not authorized");
        _;
    }

    modifier isJobAdmin{
        require(hasRole(JOB_ADMIN, msg.sender), "Not authorized");
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
     * @param _percentage Percentage increase after each payment refresh
     **/
    function createJob(
        uint256 _initAmount,
        string memory _descriptor,
        uint256 _refreshRate,
        uint256 _eventStreamId,
        uint8 _percentage
    ) public {
        require(
            _eventStreamId + 1 <= eventStreams.length,
            "Event Stream does not exist"
        );
        jobs.push(
            Job({
                creator: msg.sender,
                descriptor: _descriptor,
                amount: _initAmount,
                percentage: _percentage,
                refreshRate: _refreshRate,
                eventsRecorded: 0,
                eventStreamId: _eventStreamId,
                creatorSigned: false,
                assetCid: "",
                applicantSigned: false,
                workSubmitted: false,
                state: State.Open
            })
        );

        uint256 jobID = jobs.length - 1;
        emit JobCreated(
            msg.sender,
            _initAmount,
            _refreshRate,
            jobID,
            _eventStreamId
        );
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
        uint256 streamID = eventStreams.length - 1;
        emit EventStreamCreated(_descriptor, streamID);
    }

    /**
     * @notice The job creator can configure the down payment before finalizing his choice of applicant
     * @dev downpayment will be confirmed during the signing process
     * @param newAmount The new down payment
     * @param jobID The ID of a specific job
     **/
    function configureAmount(uint256 newAmount, uint256 jobID)
        public
        auth(jobs[jobID].creator)
        inState(State.Open, jobID)
    {
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
    function changeRefreshRate(uint8 newRefreshRate, uint256 jobID)
        public
        auth(jobs[jobID].creator)
        inState(State.Open, jobID)
    {
        require(newRefreshRate > 0, "Refresh rate needs to be greater than 0.");
        jobs[jobID].refreshRate = newRefreshRate;
    }

    /**
     * @notice Applicants apply for a specific job
     * @dev Can flesh out a little bit more, but this is probably ok for now
     * @param jobID The ID of a specific job
     **/
    function applyForJob(uint256 jobID) public inState(State.Open, jobID) {
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
    function chooseApplicant(address chosenApplicant, uint256 jobID)
        public
        auth(jobs[jobID].creator)
        inState(State.Open, jobID)
    {
        // Require that applicant exists *****
        finalApplicant[jobID] = chosenApplicant;
        jobs[jobID].state = State.Signing;
        emit ApplicantChosen(chosenApplicant, jobID);
    }

    /**
     * @notice The applicant signs off and agrees to do a job. The applicant can still withdraw from the commitment before the creator also signs off
     * @dev Add init stake to prevent bailing? May be a deterrent...
     * @param jobID The ID of a specific job
     **/
    function initApplicantSign(uint256 jobID)
        public
        auth(finalApplicant[jobID])
        inState(State.Signing, jobID)
    {
        jobs[jobID].applicantSigned = true;
        if(jobs[jobID].creatorSigned == true && jobs[jobID].applicantSigned == true) {
            jobs[jobID].state = State.Signed;
        }
        emit ApplicantSigned(msg.sender, jobID);
    }

    /**
     * @notice The creator officially signs off and the job process starts
     * @dev Check the states
     * @param jobID The ID of a specific job
     **/
    function initCreatorSign(uint256 jobID)
        public
        payable
        auth(jobs[jobID].creator)
        inState(State.Signing, jobID)
    {
        uint256 val = msg.value;
        require(jobs[jobID].amount <= val);
        jobs[jobID].creatorSigned = true;
        jobs[jobID].amount = val;
        if(jobs[jobID].creatorSigned == true && jobs[jobID].applicantSigned == true) {
            jobs[jobID].state = State.Signed;
        }
        emit CreatorSigned(msg.sender, jobID);
    }

    /**
     * @notice Signals that work is submitted. Acts as the applicant signing
     * @dev Check states. Probably need a bool for simple storage. Should emphasize
     *      communicating with the job creator before submission
     * @dev Implement states and refusals
     * @param jobID The ID of a specific job
     * @param assetCid Points to the ipfs cid of the final work, could be useful for a "mock" appstore
     **/
    function submitWork(uint256 jobID, string memory assetCid)
        public
        auth(finalApplicant[jobID])
        inState(State.Signed, jobID)
    {
        jobs[jobID].workSubmitted = true;
        jobs[jobID].assetCid = assetCid;
    }

    /**
     * @notice The job creators final sign off. Signals event tracking and the payment stream
     * @dev Include ability to refuse? Who would pay gas to refuse? Just don't pay...
     * @dev In response to above comment: could be where mediation comes in. Mediator checks work, then decides who receives stake?
     * @dev Would need to emphasize a high initAmount in that case
     * @param result Dictates whether the work is accepted or rejected. True to accept, false to reject
     * @param jobID The ID of a specific job
     **/
    function finalSign(bool result, uint256 jobID, int96 allowedFlow, int96 maxAllowedFlow, uint deadline)
        public
        auth(jobs[jobID].creator)
    {
        require(jobs[jobID].workSubmitted == true);
        jobs[jobID].state = State.Closed;
        if (result) {
            //Just to test it, all this parameters should be available from earlier (e.g. during applicant proposal)
           address newCashflow = _createNewCashflow(finalApplicant[jobID], msg.sender, jobID, allowedFlow, maxAllowedFlow, deadline);
           address acceptedToken = ITradeableCashflowWithAllowanceFactory(cashflowFactory).getAcceptedToken(jobID);
           //Transfer 1 DAIx from the buyer to the cashflow contract, the buyer need to approve the amount first 
           ISuperToken(acceptedToken).transfer(newCashflow, 1000000000000000000);
        } else if (!result) {
            // Mediation? Receive stake back after mediation?
        }
        emit FinalResult(msg.sender, finalApplicant[jobID], jobID, result);
    }
}

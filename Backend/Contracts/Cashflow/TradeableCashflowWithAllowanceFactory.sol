//SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./TradeableCashflowWithAllowance.sol";
import "./Interfaces/ITradeableCashflowWithAllowanceFactory.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

//import {ISuperToken, IConstantFlowAgreementV1, ISuperfluid} from "./RedirectAll.sol";

contract TradeableCashflowWithAllowanceFactory is ITradeableCashflowWithAllowanceFactory, AccessControl{
    address private _host; // host
    address private _cfa; // the stored constant flow agreement class address
    address private _acceptedToken; // accepted token
    address private _paymentFactory;

    bytes32 public constant JOB_ADMIN = keccak256("JOB_ADMIN");

    event NewCashFlow(uint jobId,  address recipient, address sender);
    mapping(uint => address) public cashflowsRecipient;  
    mapping(uint => address) public cashflowsSender;  

    constructor(
        address host,
        address cfa,
        address acceptedToken,
        address paymentFactory
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(JOB_ADMIN, msg.sender);

        _host = host;
        _cfa = cfa;
        _acceptedToken = acceptedToken;
        _paymentFactory = paymentFactory;
    }

    function getAcceptedToken(uint256) override public view returns(address){
        return _acceptedToken;
    }

    function updatePaymentFactory(address paymentFactory) public {
        require(hasRole(JOB_ADMIN, msg.sender), "Not authorized");
        _paymentFactory = paymentFactory;
    }


    modifier isPaymentFactory {
        require(msg.sender == _paymentFactory, "Not authorized");
        _;
    }

    function getAllowedFlow(uint256 jobId) public view override returns(int96){
        require(cashflowsRecipient[jobId] != address(0), "Job CashFlow doesn't exists");
        return TradeableCashflowWithAllowance(cashflowsRecipient[jobId])._allowedFlow();
    }


    function updateCashflowAllowance(uint256 jobId, int96 newAllowance) isPaymentFactory public override {
        require(cashflowsRecipient[jobId] != address(0), "Job CashFlow doesn't exists");
        TradeableCashflowWithAllowance(cashflowsRecipient[jobId]).updateAllowedFlow(newAllowance);
    }



    function createNewCashflow(
        address recipient,
        address sender,
        uint256 jobId,
        int96 allowedFlow,
        int96 maxAllowedFlow,
        uint256 deadline
    ) isPaymentFactory public override returns(address){
        require(cashflowsRecipient[jobId] == address(0), "JobId already used");
        TradeableCashflowWithAllowance newFlow = new TradeableCashflowWithAllowance(recipient, allowedFlow, maxAllowedFlow, deadline, msg.sender, _host, _cfa, _acceptedToken);
        address flowAddress = address(newFlow);
        cashflowsRecipient[jobId] = flowAddress;
        cashflowsSender[jobId] = sender;
        //TODO: transfer money from msg.sender to address(newFlow)
        emit NewCashFlow(jobId, flowAddress, msg.sender);
        return flowAddress;
    }
 

}

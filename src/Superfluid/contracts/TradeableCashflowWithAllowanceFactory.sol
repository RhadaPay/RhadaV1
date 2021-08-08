//SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./TradeableCashflowWithAllowance.sol";
import {ISuperToken, IConstantFlowAgreementV1, ISuperfluid} from "./RedirectAll.sol";

contract TradeableCashflowWithAllowanceFactory {
    ISuperfluid private _host; // host
    IConstantFlowAgreementV1 private _cfa; // the stored constant flow agreement class address
    ISuperToken private _acceptedToken; // accepted token

    event NewCashFlow(uint jobId,  address recipient, address sender);
    mapping(uint => address) public cashflowsRecipient;  
    mapping(uint => address) public cashflowsSender;  

    constructor(
        ISuperfluid host,
        IConstantFlowAgreementV1 cfa,
        ISuperToken acceptedToken
    ) {
        _host = host;
        _cfa = cfa;
        _acceptedToken = acceptedToken;
    }


    //TODO:role permission 
    function updateCashflowAllowance(uint256 jobId, int96 newAllowance) public {
        require(cashflowsRecipient[jobId] != address(0), "Job CashFlow doesn't exists");
        TradeableCashflowWithAllowance(cashflowsRecipient[jobId]).updateAllowedFlow(newAllowance);
    }

    function createNewCashflow(
        address recipient,
        uint256 jobId,
        int96 allowedFlow,
        int96 maxAllowedFlow,
        uint256 deadline
    ) public {
        require(cashflowsRecipient[jobId] == address(0), "JobId already used");
        TradeableCashflowWithAllowance newFlow = new TradeableCashflowWithAllowance(recipient, allowedFlow, maxAllowedFlow, deadline, msg.sender, _host, _cfa, _acceptedToken);
        cashflowsRecipient[jobId] = address(newFlow);
        cashflowsSender[jobId] = msg.sender;
        //TODO: transfer money from msg.sender to address(newFlow)
        emit NewCashFlow(jobId, address(newFlow), msg.sender);
    }
 

}

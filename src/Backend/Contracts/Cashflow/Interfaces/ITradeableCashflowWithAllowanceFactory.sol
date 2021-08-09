// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

interface ITradeableCashflowWithAllowanceFactory {
    function createNewCashflow(
        address recipient,
        address sender,
        uint256 jobId,
        int96 allowedFlow,
        int96 maxAllowedFlow,
        uint256 deadline
    ) external returns(address);

    function updateCashflowAllowance(uint256 jobId, int96 newAllowance) external;

    function getAllowedFlow(uint256 jobId) external view returns(int96);

    //JobId is not needed for now but it could allow in future to have different super token options for differents job
    function getAcceptedToken(uint256 jobId) external view returns(address);

}

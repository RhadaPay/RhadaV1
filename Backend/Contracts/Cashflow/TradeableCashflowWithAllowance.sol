//SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import {RedirectAll, ISuperToken, IConstantFlowAgreementV1, ISuperfluid} from "./RedirectAll.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TradeableCashflowWithAllowance is ERC721, RedirectAll {
    constructor(
        address owner,
        int96 allowedFlow,
        int96 maxAllowedFlow,
        uint256 deadline,
        address sender,
        address host,
        address cfa,
        address acceptedToken
    )
        ERC721("JobCashflow", "JobCashflow")
        RedirectAll(
            ISuperfluid(host),
            IConstantFlowAgreementV1(cfa),
            ISuperToken(acceptedToken),
            owner,
            allowedFlow,
            maxAllowedFlow,
            deadline,
            sender
        )
    {
        _mint(owner, 1);
    }

    //now I will insert a nice little hook in the _transfer, including the RedirectAll function I need
    function _beforeTokenTransfer(
        address, /*from*/
        address to,
        uint256 /*tokenId*/
    ) internal override {
        _changeReceiver(to);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma abicoder v2;

import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol"; //"@superfluid-finance/ethereum-monorepo/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import {SuperAppBase} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

contract RedirectAll is SuperAppBase {
    ISuperfluid private _host; // host
    IConstantFlowAgreementV1 private _cfa; // the stored constant flow agreement class address
    ISuperToken private _acceptedToken; // accepted token

    address public _receiver;
    address public _sender;
    int96 public _allowedFlow;

    event ReceiverChanged(address receiver);
    event FlowUpdated(int96 inFlow, int96 outflow, int96 refundFlow);
    event NewAgreement(address sender, address receiver);

    constructor(
        ISuperfluid host,
        IConstantFlowAgreementV1 cfa,
        ISuperToken acceptedToken,
        address receiver,
        int96 allowedFlow,
        address sender
    ) {
        require(address(host) != address(0), "host is zero address");
        require(address(cfa) != address(0), "cfa is zero address");
        require(
            address(acceptedToken) != address(0),
            "acceptedToken is zero address"
        );
        require(address(receiver) != address(0), "receiver is zero address");
        require(!host.isApp(ISuperApp(receiver)), "receiver is an app");

        _host = host;
        _cfa = cfa;
        _acceptedToken = acceptedToken;
        _receiver = receiver;
        _sender = sender;
        _allowedFlow = allowedFlow;

        uint256 configWord = SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP;

        _host.registerApp(configWord);
    }

    //Should have a restricted access
    function updateAllowedFlow(int96 newValue) public {
        if (newValue == _allowedFlow) return;

        _allowedFlow = newValue;

        (, int96 inFlowRate, , ) = _cfa.getFlow(
            _acceptedToken,
            _sender,
            address(this)
        );
        (, int96 outFlowRate, , ) = _cfa.getFlow(
            _acceptedToken,
            address(this),
            _receiver
        );
        (, int96 refundFlowRate, , ) = _cfa.getFlow(
            _acceptedToken,
            address(this),
            _sender
        );

        int96 newRefundFlow = 0;
        int96 newOutFlow = inFlowRate;

        //delete existing flows
        if (outFlowRate != 0) {
            deleteFlow(_receiver);
        }

        if (refundFlowRate != 0) {
            deleteFlow(_sender);
        }

        // Create flow
        if (inFlowRate > 0) {
            if (inFlowRate > _allowedFlow) {
                newRefundFlow = inFlowRate - _allowedFlow;
                newOutFlow -= newRefundFlow;
            }

            if (newOutFlow > 0) {
                createFlow(_receiver, newOutFlow);
            }

            if (newRefundFlow > 0) {
                createFlow(_sender, newRefundFlow);
            }
        }
        emit FlowUpdated(inFlowRate, newOutFlow, newRefundFlow);
    }

    /**************************************************************************
     * Redirect Logic
     *************************************************************************/

    function currentReceiver()
        external
        view
        returns (
            uint256 startTime,
            address receiver,
            int96 flowRate
        )
    {
        if (_receiver != address(0)) {
            (startTime, flowRate, , ) = _cfa.getFlow(
                _acceptedToken,
                address(this),
                _receiver
            );
            receiver = _receiver;
        }
    }

    /**************************************************************************
     * Utiliy methods for Superfluid
     *************************************************************************/
    function deleteFlowWithCtx(address recipient, bytes memory ctx)
        internal
        returns (bytes memory newCtx)
    {
        (newCtx, ) = _host.callAgreementWithContext(
            _cfa,
            abi.encodeWithSelector(
                _cfa.deleteFlow.selector,
                _acceptedToken,
                address(this),
                recipient,
                new bytes(0) // placeholder
            ),
            "0x",
            ctx
        );
    }

    function deleteFlow(address recipient) internal {
        _host.callAgreement(
            _cfa,
            abi.encodeWithSelector(
                _cfa.deleteFlow.selector,
                _acceptedToken,
                address(this),
                recipient,
                new bytes(0) // placeholder
            ),
            "0x"
        );
    }

    function updateFlowWithCtx(
        address recipient,
        int96 amount,
        bytes memory ctx
    ) internal returns (bytes memory newCtx) {
        (newCtx, ) = _host.callAgreementWithContext(
            _cfa,
            abi.encodeWithSelector(
                _cfa.updateFlow.selector,
                _acceptedToken,
                recipient,
                amount,
                new bytes(0) // placeholder
            ),
            "0x",
            ctx
        );
    }

    function updateFlow(address recipient, int96 amount) internal {
        _host.callAgreement(
            _cfa,
            abi.encodeWithSelector(
                _cfa.updateFlow.selector,
                _acceptedToken,
                recipient,
                amount,
                new bytes(0) // placeholder
            ),
            "0x"
        );
    }

    function createFlowWithCtx(
        address recipient,
        int96 amount,
        bytes memory ctx
    ) internal returns (bytes memory newCtx) {
        (newCtx, ) = _host.callAgreementWithContext(
            _cfa,
            abi.encodeWithSelector(
                _cfa.createFlow.selector,
                _acceptedToken,
                recipient,
                amount,
                new bytes(0) // placeholder
            ),
            "0x",
            ctx
        );
    }

    function createFlow(address recipient, int96 amount) internal {
        _host.callAgreement(
            _cfa,
            abi.encodeWithSelector(
                _cfa.createFlow.selector,
                _acceptedToken,
                recipient,
                amount,
                new bytes(0) // placeholder
            ),
            "0x"
        );
    }

    /// @dev If a new stream is opened, or an existing one is opened
    /// Redirects only _sender streams
    function _updateOutflow(bytes calldata ctx)
        private
        returns (bytes memory newCtx)
    {
        newCtx = ctx;

        (, int96 inFlowRate, , ) = _cfa.getFlow(
            _acceptedToken,
            _sender,
            address(this)
        );

        (, int96 outFlowRate, , ) = _cfa.getFlow(
            _acceptedToken,
            address(this),
            _receiver
        );

        (, int96 refundFlowRate, , ) = _cfa.getFlow(
            _acceptedToken,
            address(this),
            _sender
        );

        int96 newRefundFlow = 0;
        int96 newOutFlow = inFlowRate;

        //delete existing flows
        if (outFlowRate != 0) {
            newCtx = deleteFlowWithCtx(_receiver, newCtx);
        }

        if (refundFlowRate != 0) {
            newCtx = deleteFlowWithCtx(_sender, newCtx);
        }

        // Create flow
        if (inFlowRate > 0) {
            if (inFlowRate > _allowedFlow) {
                newRefundFlow = inFlowRate - _allowedFlow;
                newOutFlow -= newRefundFlow;
            }

            if (newOutFlow > 0) {
                newCtx = createFlowWithCtx(_receiver, newOutFlow, newCtx);
            }

            if (newRefundFlow > 0) {
                newCtx = createFlowWithCtx(_sender, newRefundFlow, newCtx);
            }
        }

        emit FlowUpdated(inFlowRate, newOutFlow, newRefundFlow);
    }

    // @dev Change the Receiver of the total flow
    function _changeReceiver(address newReceiver) internal {
        require(newReceiver != address(0), "New receiver is zero address");
        // @dev because our app is registered as final, we can't take downstream apps
        require(
            !_host.isApp(ISuperApp(newReceiver)),
            "New receiver can not be a superApp"
        );
        if (newReceiver == _receiver) return;
        (, int96 outFlowRate, , ) = _cfa.getFlow(
            _acceptedToken,
            address(this),
            _receiver
        );

        if (outFlowRate > 0) {
            // @dev delete flow to old receiver
            deleteFlow(_receiver);

            // @dev create flow to new receiver
            createFlow(newReceiver, outFlowRate);
        }
        
        // @dev set global receiver to new receiver
        _receiver = newReceiver;

        emit ReceiverChanged(_receiver);
    }

    /**************************************************************************
     * SuperApp callbacks
     *************************************************************************/

    function afterAgreementCreated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, // _agreementId,
        bytes calldata agreementData,
        bytes calldata, // _cbdata,
        bytes calldata _ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        //Only consider flows from the sender
        (address flowSender, address flowReceiver) = abi.decode(
            agreementData,
            (address, address)
        );
        emit NewAgreement(flowSender, flowReceiver);

        if (flowSender == _sender) {
            return _updateOutflow(_ctx);
        } else {
            return _ctx;
        }
    }

    function afterAgreementUpdated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, //_agreementId,
        bytes calldata agreementData,
        bytes calldata, //_cbdata,
        bytes calldata _ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        //Only consider flows from the sender
        (address flowSender, address flowReceiver) = abi.decode(
            agreementData,
            (address, address)
        );
        emit NewAgreement(flowSender, flowReceiver);

        if (flowSender == _sender) {
            return _updateOutflow(_ctx);
        } else {
            return _ctx;
        }
    }

    function afterAgreementTerminated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, //_agreementId,
        bytes calldata agreementData,
        bytes calldata, //_cbdata,
        bytes calldata _ctx
    ) external override onlyHost returns (bytes memory newCtx) {
        //TODO: handle contract termination
        // According to the app basic law, we should never revert in a termination callback
        if (!_isSameToken(_superToken) || !_isCFAv1(_agreementClass))
            return _ctx;
        //Only consider flows from the sender
        (address flowSender, address flowReceiver) = abi.decode(
            agreementData,
            (address, address)
        );
        emit NewAgreement(flowSender, flowReceiver);

        if (flowSender == _sender) {
            return _updateOutflow(_ctx);
        } else {
            return _ctx;
        }
    }

    function _isSameToken(ISuperToken superToken) private view returns (bool) {
        return address(superToken) == address(_acceptedToken);
    }

    function _isCFAv1(address agreementClass) private view returns (bool) {
        return
            ISuperAgreement(agreementClass).agreementType() ==
            keccak256(
                "org.superfluid-finance.agreements.ConstantFlowAgreement.v1"
            );
    }

    modifier onlyHost() {
        require(
            msg.sender == address(_host),
            "RedirectAll: support only one host"
        );
        _;
    }

    modifier onlyExpected(ISuperToken superToken, address agreementClass) {
        require(_isSameToken(superToken), "RedirectAll: not accepted token");
        require(_isCFAv1(agreementClass), "RedirectAll: only CFAv1 supported");
        _;
    }
}

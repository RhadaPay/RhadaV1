const TradeableCashflow = artifacts.require("TradeableCashflow");
const TradeableCashflowFactory = artifacts.require("TradeableCashflowFactory");

module.exports = function (deployer) {
  deployer.deploy(TradeableCashflowFactory, TradeableCashflow.address, "0x22ff293e14F1EC3A09B137e9e06084AFd63adDF9", "0xEd6BcbF6907D4feEEe8a8875543249bEa9D308E8" );
};

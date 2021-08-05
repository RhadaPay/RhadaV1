const TradeableCashflow = artifacts.require("TradeableCashflow");

module.exports = function (deployer) {
  deployer.deploy(TradeableCashflow);
};

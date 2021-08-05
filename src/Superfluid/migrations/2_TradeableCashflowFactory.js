const TradeableCashflowWithAllowanceFactory = artifacts.require("TradeableCashflowWithAllowanceFactory");

module.exports = function (deployer) {
  const host = "0xEB796bdb90fFA0f28255275e16936D25d3418603";
  const cfa = "0x49e565Ed1bdc17F3d220f72DF0857C26FA83F873";
  const acceptedtoken = "0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f";

  deployer.deploy(TradeableCashflowWithAllowanceFactory,  host, cfa, acceptedtoken);
};

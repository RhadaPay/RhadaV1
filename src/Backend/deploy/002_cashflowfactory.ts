import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction, DeployResult} from 'hardhat-deploy/types';
import { PaymentFactory, PaymentFactory__factory } from '../typechain';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;

  const {deployer, host, cfa, acceptedToken} = await getNamedAccounts();
  const paymentFactoryAddress = await (await deployments.get("PaymentFactory")).address;

  let cashflowFactory : DeployResult = await deploy('TradeableCashflowWithAllowanceFactory', {
    from: deployer,
    args: [host, cfa, acceptedToken, paymentFactoryAddress],
    log: true,
  });

  await deployments.execute("PaymentFactory", {from: deployer, log: true}, "updateCashflowFactoryAddress", cashflowFactory.address)

};
export default func;
func.tags = ['TradeableCashflowWithAllowanceFactory'];
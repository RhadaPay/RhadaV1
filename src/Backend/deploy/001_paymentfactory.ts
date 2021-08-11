import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;

  const {deployer, oracle} = await getNamedAccounts();

  await deploy('PaymentFactory', {
    from: deployer,
    args: ["0x0000000000000000000000000000000000000000"],
    log: true,
  });

  //Grant Job Oracle role to oracle address
  await deployments.execute("PaymentFactory",
   {from: deployer, log: true}, "grantRole", "0xa808c4eaf01d2f146a6c19de0017325e6046f29783433fc1500ba564ec7cfe5b", oracle)


};
export default func;
func.tags = ['PaymentFactory'];
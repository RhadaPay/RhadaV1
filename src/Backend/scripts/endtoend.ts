import { run, ethers, deployments, getNamedAccounts } from "hardhat";
import { PaymentFactory, PaymentFactory__factory } from "../typechain";

async function main() {
  const {buyer, seller, host, cfa, acceptedToken} = await getNamedAccounts();
  await ethers.getSigner(buyer)
  const paymentFactory : PaymentFactory__factory = await ethers.getContractFactory("PaymentFactory") as PaymentFactory__factory;
  const paymentFactoryContract : PaymentFactory = paymentFactory.attach((await deployments.get("PaymentFactory")).address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

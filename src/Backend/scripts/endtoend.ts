import { BigNumber, BigNumberish } from "ethers";
import { run, ethers, deployments, getNamedAccounts } from "hardhat";
import { ISuperToken, ISuperToken__factory, PaymentFactory, PaymentFactory__factory } from "../typechain";
import { Framework } from "@superfluid-finance/js-sdk";
let buyerContract : PaymentFactory;
let sellerContract: PaymentFactory;

async function createEventStream(descriptor:string) : Promise<number> {
  let tx = await (await sellerContract.createEventStream(descriptor)).wait();
  let eventStreamId = ((tx.events?.find(ev => ev?.args?.streamID)?.args?.streamID) as BigNumber).toNumber();

  console.log(`Event stream created: Tx Hash ${tx.transactionHash}, Event Stream Id ${eventStreamId} `);
  return eventStreamId;

}

async function createJob(initAmount:number, descriptor: string, refreshRate: number, eventStreamId: number, deadline: number, percentage: number) : Promise<number> {
  let tx = await (await buyerContract.createJob(initAmount, descriptor, refreshRate, eventStreamId, deadline, percentage)).wait();
  let jobID = ((tx.events?.find(ev => ev?.args?.jobID)?.args?.jobID) as BigNumber).toNumber();
  console.log(`Job created: Tx Hash ${tx.transactionHash}, Job Id ${jobID} `);
  return jobID;
}

async function applyForJob(jobID:number) {
  let tx = await (await sellerContract.applyForJob(jobID)).wait();
  console.log(`Applied for job: Tx Hash ${tx.transactionHash}`)
}

async function chooseApplicant(address:string, jobID:number) {
  let tx = await (await buyerContract.chooseApplicant(address, jobID)).wait()
  console.log(`Chosen applicant for job: Tx Hash ${tx.transactionHash}`) 
}

async function initCreatorSign(jobID:number, amount:number) {
 let tx = await (await buyerContract.initCreatorSign(jobID, {value: amount} )).wait()
 console.log( `init creator sign: ${tx.transactionHash} `)
}

async function initApplicantSign(jobID:number) {
  let tx = await (await sellerContract.initApplicantSign(jobID)).wait()
  console.log( `init applicant sign: ${tx.transactionHash} `)
}

async function submitWork(jobID:number, assetCID: string) {
  let tx = await (await (await sellerContract.submitWork(jobID, assetCID)).wait())
  console.log( `Submit Work: ${tx.transactionHash} `)
}

async function finalSign(jobID: number, allowedFlow: BigNumberish, maxAllowedFlow: BigNumberish) {
 let tx = await( (await buyerContract.finalSign(true, jobID, allowedFlow, maxAllowedFlow)).wait())
 console.log( `Final Sign ${tx.transactionHash}`)
}

async function main() {
  const {buyer, seller, host, cfa, acceptedToken} = await getNamedAccounts();
  let signerBuyer = await ethers.getSigner(buyer);
  let signerSeller = await ethers.getSigner(seller);
  console.log(`seller address: ${seller}, buyer address: ${buyer}`)
  //const paymentFactory : PaymentFactory__factory = await ethers.getContractFactory("PaymentFactory") as PaymentFactory__factory;
  const paymentFactoryAddress = (await deployments.get("PaymentFactory")).address;

  let daix = await ethers.getContractAt("ISuperToken", acceptedToken, signerBuyer) as ISuperToken;

  buyerContract = PaymentFactory__factory.connect(paymentFactoryAddress, signerBuyer);
  sellerContract = PaymentFactory__factory.connect(paymentFactoryAddress, signerSeller);

  //1. Create Event Stream
  let eventStreamId = await createEventStream("test");
  //2. Create Job
  const today = new Date()
  const tomorrow = (new Date(today))
  tomorrow.setDate(tomorrow.getDate() + 1)
  let amount = 1;
  let jobID = await createJob(amount, "test", 1, eventStreamId, Math.floor(tomorrow.getMilliseconds() / 1000), 5)
  //3. Apply to Job
  applyForJob(jobID)
  //4. Chose applicant
  chooseApplicant(seller, jobID)
  //5. initCreatorSign
 initCreatorSign(jobID, amount)
  //6. initApplicantSign
 initApplicantSign(jobID)
  //7. Submit Work
 submitWork(jobID, "test")

  //Approve 1 DAIX
  let tx = await (await daix.approve(paymentFactoryAddress, "1000000000000000000")).wait()
  console.log("daix approved: ", tx.transactionHash);
  
  //8. finalSign
  finalSign(jobID, "289351851851852"/* 750 per month */, "578703703703704"/* 1500 per month */)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

import { ethers } from "hardhat";
import { Job } from "../interfaces/Job";

import { PaymentFactory, PaymentFactory__factory } from '../typechain'

let abi = []

let provider = ethers.getDefaultProvider('mumbai');

let contractAddress = "0x6ddbA220bc7700cd03e97dA8c418cFA166Fc2647";

let factory = new ethers.contractAddress(contractAddress, abi, provider);

filter = {
    address: contractAddress,
    topics: [
        utils.id("JobCreated(address,uint256,uint256,uint256,uint256)"),
        utils.id("EventStreamCreated(string,uint256)"),
        utils.id("AmountChanged(string,uint256)"),
        utils.id("ApplicantApplied(address,uint256)"),
        utils.id("ApplicantChosen(address,uint256)"),
        utils.id("ApplicantSigned(address,uint256)"),
        utils.id("CreatorSigned(address,uint256)"),
        utils.id("JobCompleted(uint256)"),
        utils.id("FinalSign(address,address,uint256)"),
        utils.id("FinalResult(address,address,uint256,bool)"),
        utils.id("UpdateNumberOfEvents(uint256,uint256)")
    ]
}
provider.on(filter, (log, event) => {
    
})
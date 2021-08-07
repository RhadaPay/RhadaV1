const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Payment Factory", function () {
    let PaymentFactory;
    let factory;
    let buyer1;
    let buyer2;
    let seller1;
    let seller2;
    let seller3;

    before(async function () {
        PaymentFactory = await ethers.getContractFactory("PaymentFactory");
        [buyer1, buyer2, seller1, seller2, seller3] = await ethers.getSigners();
        factory = await PaymentFactory.deploy();
    });
    
    describe("Deployment", function () {
        it("Deployment results in nothing for now", async function () {
        })
    });

    describe("Create job", function () {
        it("New job should have jobID 0", async function () {
            let _batches = ["0", "1", "2"];
            //const job1 = await factory.connect(buyer1).createJob(1000, _batches, 10);
            //expect(factory.jobs[0]).to.equal(job1);
        });
    });



});
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
            const job1 = await factory.connect(buyer1).createJob(1000, _batches, 10);
            //expect(await factory.jobs(0)).to.equal(job1);
        });

        it("Creator should be buyer1", async function () {
            expect(await factory.jobCreator(0)).to.equal(buyer1.address);
            
        });

        it("Amount should be 1000", async function () {
            expect(await factory.jobAmount(0)).to.equal(1000);
        });

        it("Creator signed should be false", async function () {
            expect(await factory.jobCreatorSignature(0)).to.equal(false);
        });

        it("Applicant signed should be false", async function () {
            expect(await factory.jobApplicantSignature(0)).to.equal(false);
        });

        it("Work submitted should be false", async function () {
            expect(await factory.jobWorkSubmitted(0)).to.equal(false);
        });

        it("", async function () {
            //expect(await factory.jobAmount(0)).to.equal(1000);
        });

        it("State should be open", async function () {
            //expect(await factory.jobState(0)).to.equal(factory.State);
        });
    });



});
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
    
    after(async () => {
        await new Promise(resolve => setTimeout(() => resolve(), 0));
      });

    describe("Deployment", function () {
        it("Deployment results in nothing for now", async function () {

        });
    });

    describe("Create job", function () {
        it("New job should have jobID 0", async function () {
            const job1 = await factory.connect(buyer1).createJob(1000, 10);
            //expect(await factory.jobs(0)).to.equal(job1);
        });

        it("Creator should be buyer1", async function () {
            console.log(factory.jobs);
            expect(await factory.jobCreator(0)).to.equal(buyer1.address);
        });

        it("Amount should be 1000", async function () {
            expect(await factory.jobAmount(0)).to.equal(1000);
        });

        it("EventsRemainder should be 0", async function () {
            expect(await factory.jobRemainder(0)).to.equal(0);
        });

        it("RefreshRate should be 10", async function () {
            expect(await factory.jobRefreshRate(0)).to.equal(10);
        });

        it("StreamIDs should be an empty array", async function () {
            expect(await factory.jobEventStreamIDs(0)).to.equal([]);
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

        it("State should be open", async function () {
            expect(await factory.jobState(0)).to.equal(0);
        });
    });

    describe("Creating event streams", function () {
        it("Create event stream with ID 0", async function () {
            let cids = ["fchash1", "fchash2", "fchash3"]
            const stream1 = await factory.createEventStream("Test Stream", cids);
            //expect(await factory.eventStreams(0)).to.equal(stream1);
        });

        it("Descriptor should be Test Stream", async function () {
            expect(await factory.streamDescriptor(0)).to.equal("Test Stream");
        });

        it("List of CIDs should be equal to FILL IN", async function () {
            expect(await factory.streamCIDs(0)).to.equal(cids);
        });
    });

    describe("Add event stream", function () {
        it("Create more event streams for testing purposes", async function () {

        });

        it("Check adding non-existant streamIDs", async function () {

        });

        it("Check auth", async function () {

        });

        it("Check updated states", async function () {

        });
    });

    describe("Configure amount", function () {
        it("Amount equal to 0", async function () {

        });

        it("Amount less than 0", async function () {

        });

        it("Valid amount", async function () {

        });

        it("Check auth", async function () {

        });
    });
});
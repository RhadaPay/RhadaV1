import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { Job } from "../interfaces/Job";

import { PaymentFactory, PaymentFactory__factory } from '../typechain'

describe("Payment Factory", function () {
    let PaymentFactory: PaymentFactory__factory;
    let factory: PaymentFactory;
    let [buyer1, seller1] = [] as SignerWithAddress[];

    before(async function () {
        PaymentFactory = await ethers.getContractFactory("PaymentFactory") as PaymentFactory__factory;
        [buyer1, seller1] = await ethers.getSigners();
        factory = await PaymentFactory.deploy();
      });
    
    after(async () => {
        await new Promise<void>(resolve => setTimeout(() => resolve(), 0));
      });

    describe("Create jobs", () => {
        let job: Job;
        const _eventStreamId = 0;
        const newJob = {
          _initAmount: 1000,
          _refreshRate: 10,
          _eventStreamId
        }
        
        before(async () => {
          await factory.createEventStream("test");
          await factory.connect(buyer1).createJob(
            newJob._initAmount, newJob._refreshRate, newJob._eventStreamId
          );
          job = await factory.jobs(0);
        })

        it("Creates a new job with id 0", async function () {
            expect(Boolean(job)).to.equal(true);
        });

        it("Reverts if the event stream isn't recognised", async function () {
          await expect(
            factory
            .connect(buyer1)
            .createJob(newJob._initAmount, newJob._refreshRate, 10)
          ).to.be.reverted;
        });

        it("Creator should be buyer1", async function () {
            expect(job.creator).to.equal(buyer1.address);
        });

        it(`Amount should be ${newJob._initAmount}`, async function () {
            expect(job.amount).to.equal(newJob._initAmount);
        });

        it(`Refresh Rate should be ${newJob._refreshRate}`, async function () {
            expect(job.refreshRate).to.equal(newJob._refreshRate);
        });

        it("events recorded should be 0", async function () {
          expect(job.eventsRecorded).to.equal(0);
        });

        it(`Event Stream id should be ${_eventStreamId}`, async function () {
          expect(job.eventStreamId).to.equal(newJob._eventStreamId);
        });

        it("Creator signed should be false", async function () {
            expect(job.creatorSigned).to.equal(false);
        });

        it("Applicant signed should be false", async function () {
            expect(job.applicantSigned).to.equal(false);
        });

        it("Work submitted should be false", async function () {
            expect(job.workSubmitted).to.equal(false);
        });

        it("State should be open", async function () {
            expect(job.state).to.equal(0);
        });
    });
});
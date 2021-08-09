import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { PaymentFactory, PaymentFactory__factory } from "../typechain";

describe("Payment Factory", function () {
  let PaymentFactory: PaymentFactory__factory;
  let factory: PaymentFactory;

  before(async function () {
    PaymentFactory = await ethers.getContractFactory("PaymentFactory") as PaymentFactory__factory;
    factory = await PaymentFactory.deploy("0x0000000000000000000000000000000000000000");
  });
  
  after(async () => {
    await new Promise<void>(resolve => setTimeout(() => resolve(), 0));
  });

  describe("Creating event streams", function () {

    const testStreamName = "Test Stream";

    it("Can create a event streams", async function () {
        await factory.createEventStream(testStreamName);
        await factory.createEventStream(testStreamName + "2");
    });

    it("Descriptor should be Test Stream", async function () {
      const eventStream = await factory.eventStreams(0);
      expect(eventStream).to.equal(testStreamName);
    });

    it("Can retrieve event streams collectively", async function () {
      const streams = await factory.getEventStreams();
      console.log(streams);
      expect(streams.length).to.equal(2);
    });
  });
});
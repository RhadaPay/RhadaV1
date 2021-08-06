const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Payment Factory", function () {
    let PaymentFactory;
    let contract;
    let buyer1;
    let buyer2;
    let seller1;
    let seller2;
    let seller3;
    let job1;
    let job2;

    beforeAll(async function () {
        PaymentFactory = await ethers.getContractFactory("PaymentFactory");
        [buyer1, buyer2, seller1, seller2, seller3] = await ethers.getSigners();
        contract = await PaymentFactory.deploy();
    });
    
    describe("Deployment", function () {
        it("Deployment results in nothing for now", async function () {
        })
    })



});
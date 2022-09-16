const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { parseUnits18 } = require("../utils/parseUnits.js");
const hre = require("hardhat");

describe("Rental Agreement", function () {
  let landlord, tenant, lendingServiceContract;
  let daiContract, rent, rentDeposit, securityDeposit, rental;
  const FOUR_WEEKS_IN_SECS = 2419200;

  beforeEach(async () => {
    [landlord, tenant] = await ethers.getSigners();

    //deploy ERC20 token to mock DAI
    const daiFactory = await ethers.getContractFactory(
      "ERC20PresetMinterPauser"
    );
    daiContract = await daiFactory.deploy("dai", "DAI");
    console.log("dai deployed at:", daiContract.address);

    //Give funds to landlord
    const initalLandlordBalance = parseUnits18("1000000");
    const txResp = await daiContract.mint(
      tenant.address,
      initalLandlordBalance
    );
    await txResp.wait();

    assert.equal(
      (await daiContract.balanceOf(tenant.address)).toString(),
      initalLandlordBalance.toString()
    );
  });

  beforeEach(async () => {
    rent = parseUnits18("500");
    securityDeposit = parseUnits18("500");
    rentDeposit = parseUnits18("1500");

    //deploy mock lending service

    const mockLendingService = await ethers.getContractFactory(
      "MockLendingService"
    );
    mockLendingService.connect(landlord);
    lendingServiceContract = await mockLendingService.deploy(
      daiContract.address
    );

    //deploy rental agreement
    const rentalAgreement = await ethers.getContractFactory("RentalAgreement");

    rentalAgreement.connect(landlord);

    rental = await rentalAgreement.deploy(
      rent,
      landlord.address,
      tenant.address,
      rentDeposit,
      securityDeposit,
      lendingServiceContract.address,
      daiContract.address
    );

    //transfer ownership of lending service to rental agreement
    const transferOwnership = await lendingServiceContract
      .connect(landlord)
      .transferOwnership(rental.address);
    await transferOwnership.wait();
  });

  describe("enter agreement", function () {
    it("should let tenants enter agreement", async () => {
      const deposits = rent.add(rentDeposit);
      const totalUpFront = deposits.add(securityDeposit);

      //tenants coins are approved
      const approvTx = await daiContract
        .connect(tenant)
        .approve(rental.address, totalUpFront);
      await approvTx.wait();

      //enter agreement
      const contract = await rental
        .connect(tenant)
        .enterAgreementAsTenant(
          rent,
          landlord.address,
          rentDeposit,
          securityDeposit
        );

      const transReciept = await contract.wait();
      const blockHash = transReciept.blockHash;
      const block = await ethers.provider.getBlock(blockHash);
      const nextBlockTimestamp = await rental.nextTimestamp();

      assert.equal(block.timestamp + FOUR_WEEKS_IN_SECS, nextBlockTimestamp);
    });
  });
});

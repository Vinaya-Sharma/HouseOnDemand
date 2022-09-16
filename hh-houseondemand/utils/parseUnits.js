const { BigNumber } = require("ethers");
const hre = require("hardhat");
const { ethers } = hre;

const parseUnits18 = (stringToParse) => ethers.utils.parseEther(stringToParse);

module.exports = {
  parseUnits18,
};

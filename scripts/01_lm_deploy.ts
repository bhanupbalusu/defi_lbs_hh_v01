import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  // LendingModule contructor values for deployment
  const annualInterestRate = 5;
  const oracleAddress = "";
  // const jobId = ethers.encodeBytes32String("LM_Test_JobID_01");
  const jobId = "";
  const fee = 1 / 10;
  // const fee = ethers.parseEther("0.1");

  const LendingModule = await ethers.getContractFactory("LendingModule");
  const lendingModule = await LendingModule.deploy(
    annualInterestRate,
    oracleAddress,
    jobId,
    fee
  );
  await lendingModule.waitForDeployment();
  const contractAddress = await lendingModule.getAddress();
  console.log(`LendingModule deployed to : ${contractAddress}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });

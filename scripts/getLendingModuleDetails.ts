import { ethers, network } from "hardhat";
import { LendingModule__factory } from "../typechain-types";

async function main() {
  const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  const [signer] = await ethers.getSigners();

  const lendingModuleContract = LendingModule__factory.connect(
    contractAddress,
    signer
  );

  try {
    const annualInterestRate = await lendingModuleContract.annualInterestRate();
    console.log(`Annual Interest Rate : ${annualInterestRate}`);

    // testing deposit
    const depositAmount = ethers.parseEther("1.0");
    const tx = await lendingModuleContract.deposit({ value: depositAmount });
    tx.wait();
    console.log(`deploy transaction confirmed`);

    // Increase time by one year
    await network.provider.send("evm_increaseTime", [31536000]); // 365 days
    await network.provider.send("evm_mine"); // Mine the next block

    // testing getBalance
    const balanceAmount = await lendingModuleContract.getBalance(
      signer.address
    );
    console.log(`balance amount is : ${ethers.formatEther(balanceAmount)} ETH`);

    // testing calculateInterest
    const interestAmount = await lendingModuleContract.calculateInterest(
      signer.address
    );
    console.log(
      `interest amount is : ${ethers.formatEther(interestAmount)} ETH`
    );

    // testing acrueInterest
    const acruedInterestTx = await lendingModuleContract.acrueInterest();
    console.log(
      `acrued interest transaction hash is : ${acruedInterestTx.hash}`
    );

    // testing getBalance
    const updateBalanceAmount = await lendingModuleContract.getBalance(
      signer.address
    );
    console.log(
      `balance amount is : ${ethers.formatEther(updateBalanceAmount)} ETH`
    );

    // Send a transaction to request the credit score
    // const tx1 = await lendingModuleContract.requestCreditScore(signer.address);
    const tx1 = await lendingModuleContract.requestCreditScore();
    // console.log("Request Credit Score transaction sent. Hash:", tx1.hash);

    // // Wait for the transaction to be mined
    // await tx1.wait();
    console.log("Request Credit Score transaction confirmed.");

    const userCreditScore = await lendingModuleContract.getUserCreditScore(
      signer.address
    );
    console.log(`User credit score is : ${userCreditScore}`);
  } catch (error) {
    console.log(`Error accessing contract data : ${error}`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

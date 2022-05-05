import pkg from "hardhat";
const { ethers } = pkg;

async function main() {
  const HeatToken = await ethers.getContractFactory("HeatToken"); 
  const contract = await HeatToken.deploy();

  await contract.deployed();

  console.log("HeadToken deployed to:", contract.address);
  return contract.address;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
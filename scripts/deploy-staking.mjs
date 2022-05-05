import pkg from "hardhat";
const { ethers } = pkg

async function main(heatTokenAddress) {
  const tokenAddress = "0xF6a8D95545a17D5CaB0C5F839e722857DD3eDc78"
  // const defaultHeatToken = '0xf18fd1dB5f39d5B96403Eea02885daF741F1e39c'; // TOOD: change if necessary
  const CyberlionStaking = await ethers.getContractFactory("CyberlionStaking"); 
  const contract = await CyberlionStaking.deploy(tokenAddress);

  await contract.deployed();

  console.log("CyberlionStaking deployed to:", contract.address);
  return contract.address
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
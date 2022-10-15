require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  gasReporter: {
    enabled: true
  },
  defaultNetwork: "hardhat",
  solidity: "0.8.17",
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true
  },
    goerli: {
      url: "https://goerli.infura.io/v3/032b7174b71b4e52b3f63bfc24976652", //Infura url with projectId
      accounts: ["099deb947c9f54c82861836301865bb686758585fcc01044cc59c1cf88476b67"] // add the account that will deploy the contract (private key)
     },
   }
};

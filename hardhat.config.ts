import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.19",
  networks: {
    localhost: {
      chainId: 31337,
      url: "http://127.0.0.1:8545",
    },
    sepolia: {
      url: "https://sepolia.infura.io/v3/3bf5919716f24474af10c7673bc51261",
      accounts: [
        `0x4f838d921d268e4687f4752313a440d28e5c0007736540af8dd900128f3e3df7`,
      ],
    },
  },
};

export default config;

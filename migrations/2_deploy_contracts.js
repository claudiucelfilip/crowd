const ConvertLib = artifacts.require("ConvertLib");
const MetaCoin = artifacts.require("MetaCoin");
const Democracy = artifacts.require("Democracy");
const SimpleToken = artifacts.require("SimpleToken");
const Bank = artifacts.require("Bank");

module.exports = async function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(MetaCoin);
  
  
  await deployer.deploy(SimpleToken, 1000000, "0x6E11ce32327C8Ca07247a11DE0BFdDa36D9e6886");
  await deployer.deploy(Bank, SimpleToken.address);
  await deployer.deploy(Democracy, SimpleToken.address, Bank.address);
  deployer.link(SimpleToken, Bank, Democracy);
};

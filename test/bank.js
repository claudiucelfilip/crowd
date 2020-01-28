const SimpleToken = artifacts.require("SimpleToken");
const Bank = artifacts.require("Bank");
const Democracy = artifacts.require("Democracy");

contract("Bank", accounts => {
  it("should transfer tokens from one account to another", async () => {
    const simpleToken = await SimpleToken.deployed();
    const bank = await Bank.deployed();

    const supply = await simpleToken.totalSupply();
    const firstBalance = await simpleToken.balanceOf(accounts[0]);
    const secondBalance = await simpleToken.balanceOf(accounts[1]);
    assert.equal(firstBalance.toNumber(), supply.toNumber());
    assert.equal(secondBalance.toNumber(), 0);

    await simpleToken.approve(bank.address, 1000, {
      from: accounts[0]
    });
    await bank.transferFrom(accounts[0], accounts[1], 1000);

    const firstBalanceAfter = await simpleToken.balanceOf(accounts[0]);
    const secondBalanceAfter = await simpleToken.balanceOf(accounts[1]);

    assert.equal(firstBalanceAfter.toNumber(), firstBalance.toNumber() - 1000);
    assert.equal(secondBalanceAfter.toNumber(), 1000);
  });
});

const SimpleToken = artifacts.require("SimpleToken");
const Democracy = artifacts.require("Democracy");
const Bank = artifacts.require("Bank");
const Web3 = require("web3");

contract("Democracy", accounts => {
  it("should have add tokens for first and second account", async () => {
    const simpleToken = await SimpleToken.deployed();
    const democracy = await Democracy.deployed();
    const supply = await simpleToken.totalSupply();

    const secondAccountAmount = 1300;
    const firstAccountAmount = 1000;

    let balanceFirst = await simpleToken.balanceOf(accounts[1]);
    let balanceSecond = await simpleToken.balanceOf(accounts[2]);

    assert.equal(balanceFirst, 0, "first account should be empty");
    assert.equal(balanceSecond, 0, "second account should be empty");

    await democracy.join({
      from: accounts[1],
      value: web3.utils.toWei(firstAccountAmount + "", "wei")
    });
    await democracy.join({
      from: accounts[2],
      value: web3.utils.toWei(secondAccountAmount + "", "wei")
    });

    balanceFirst = await simpleToken.balanceOf(accounts[1]);
    balanceSecond = await simpleToken.balanceOf(accounts[2]);

    console.log(balanceFirst.toNumber(), balanceSecond.toNumber());

    assert.equal(
      balanceFirst.toNumber(),
      firstAccountAmount,
      "first account should have " + firstAccountAmount
    );
    assert.equal(
      balanceSecond.toNumber(),
      secondAccountAmount,
      "second account should have " + secondAccountAmount
    );
  });

  it("should create new proposal", async () => {
    const democracy = await Democracy.deployed();

    const data = [1, 2, 3];
    const amount = 100;
    const description = "descripted";

    await democracy.newProposal(accounts[3], amount, data, description);

    const proposal = await democracy.proposals(0);
    const numProposals = await democracy.numProposals();

    assert.equal(numProposals, 1, "proposal length should be 1");

    assert.equal(
      proposal.amount,
      amount,
      "proposal amount should be " + amount
    );
    assert.equal(
      proposal.description,
      description,
      "proposal description should be " + description
    );
    assert.equal(proposal.active, true, "proposal should be active");
  });

  it("should vote new proposal", async () => {
    const democracy = await Democracy.deployed();
    const simpleToken = await SimpleToken.deployed();
    const bank = await Bank.deployed();
    console.log("contract address", democracy.address);
    console.log("simpleToken address", simpleToken.address);
    console.log("token address", await democracy.token());
    console.log("bank address", bank.address);

    console.log(
      "voter 1",
      accounts[1],
      (await simpleToken.balanceOf(accounts[1])).toNumber()
    );
    console.log(
      "voter 2",
      accounts[2],
      (await simpleToken.balanceOf(accounts[2])).toNumber()
    );
    console.log("recipieint", accounts[3]);
    const { tx } = await democracy.vote(0, 1, { from: accounts[1] });

    console.log("txxxxxxxxxxxxx", tx);
    await democracy.vote(0, 1, { from: accounts[2] });

    const firstVoted = await democracy.hasVoted.call(0, accounts[1]);
    const secondVoted = await democracy.hasVoted.call(0, accounts[2]);
    const thirdVoted = await democracy.hasVoted.call(0, accounts[3]);
    assert.equal(firstVoted, true, "first accont has voted");
    assert.equal(secondVoted, true, "second accont has voted");
    assert.equal(thirdVoted, false, "third accont has  not voted");

    const votesLen = await democracy.getVotesLen(0);
    assert.equal(votesLen, 2, "2 votes should be casted");
  });

  it("should execute proposal", async () => {
    const democracy = await Democracy.deployed();
    const simpleToken = await SimpleToken.deployed();

    const now = await democracy.now();
    await democracy.setBlockTime(now + 1);
    const firstTokensBefore = await simpleToken.balanceOf(accounts[1]);
    const secondTokensBefore = await simpleToken.balanceOf(accounts[2]);

    await democracy.executeProposal(0);
    const proposal = await democracy.proposals(0);

    const recipientTokens = await simpleToken.balanceOf(proposal.recipient);

    const firstTokensAfter = await simpleToken.balanceOf(accounts[1]);
    const secondTokensAfter = await simpleToken.balanceOf(accounts[2]);

    assert.equal(
      recipientTokens,
      firstTokensBefore.toNumber() + secondTokensBefore.toNumber(),
      "recipient should acuulate all tokens"
    );

    assert.equal(firstTokensAfter, 0, "first account should be 0");
    assert.equal(secondTokensAfter, 0, "second account should be 0");

    const { tx } = await democracy.withdraw({ from: proposal.recipient });
    console.log("tx", tx);

    const newRecipientTokens = await simpleToken.balanceOf(proposal.recipient);
    assert.equal(
      newRecipientTokens,
      0,
      "recipient should have withdrawn all tokens"
    );
  });
});

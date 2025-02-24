import { expect } from "@test/chai";
import { defaultKrAssetArgs, defaultMintAmount, Error, Role, withFixture } from "@utils/test";
import hre from "hardhat";

describe("KreskoAsset", () => {
    let KreskoAsset: KreskoAsset;

    withFixture(["minter-test", "krAsset"]);

    beforeEach(async function () {
        KreskoAsset = hre.krAssets.find(asset => asset.deployArgs.symbol === defaultKrAssetArgs.symbol).contract;
        // Grant minting rights for test deployer
        await KreskoAsset.grantRole(Role.OPERATOR, hre.addr.deployer);
    });
    describe("#rebase", () => {
        it("can set a positive rebase", async function () {
            const denominator = hre.toBig("1.525");
            const positive = true;
            await expect(KreskoAsset.rebase(denominator, positive)).to.not.be.reverted;
            expect(await KreskoAsset.isRebased()).to.equal(true);
            const rebaseInfo = await KreskoAsset.rebaseInfo();
            expect(rebaseInfo.denominator).equal(denominator);
            expect(rebaseInfo.positive).equal(true);
        });

        it("can set a negative rebase", async function () {
            const denominator = hre.toBig("1.525");
            const positive = false;
            await expect(KreskoAsset.rebase(denominator, positive)).to.not.be.reverted;
            expect(await KreskoAsset.isRebased()).to.equal(true);
            const rebaseInfo = await KreskoAsset.rebaseInfo();
            expect(rebaseInfo.denominator).equal(denominator);
            expect(rebaseInfo.positive).equal(false);
        });

        it("can be disabled by setting the denominator to 1 ether", async function () {
            const denominator = hre.toBig(1);
            const positive = false;
            await expect(KreskoAsset.rebase(denominator, positive)).to.not.be.reverted;
            expect(await KreskoAsset.isRebased()).to.equal(false);
        });

        describe("#balance + supply", () => {
            it("has no effect when not enabled", async function () {
                await KreskoAsset.mint(hre.addr.deployer, defaultMintAmount);
                expect(await KreskoAsset.isRebased()).to.equal(false);
                expect(await KreskoAsset.balanceOf(hre.addr.deployer)).to.equal(defaultMintAmount);
            });

            it("increases balance and supply with positive rebase @ 2", async function () {
                const denominator = 2;
                const positive = true;
                await KreskoAsset.mint(hre.addr.deployer, defaultMintAmount);
                await KreskoAsset.rebase(hre.toBig(denominator), positive);

                expect(await KreskoAsset.balanceOf(hre.addr.deployer)).to.equal(defaultMintAmount.mul(denominator));
                expect(await KreskoAsset.totalSupply()).to.equal(defaultMintAmount.mul(denominator));
            });

            it("increases balance and supply with positive rebase @ 3", async function () {
                const denominator = 3;
                const positive = true;
                await KreskoAsset.mint(hre.addr.deployer, defaultMintAmount);
                await KreskoAsset.rebase(hre.toBig(denominator), positive);

                expect(await KreskoAsset.balanceOf(hre.addr.deployer)).to.equal(defaultMintAmount.mul(denominator));
                expect(await KreskoAsset.totalSupply()).to.equal(defaultMintAmount.mul(denominator));
            });

            it("increases balance and supply with positive rebase  @ 100", async function () {
                const denominator = 100;
                const positive = true;
                await KreskoAsset.mint(hre.addr.deployer, defaultMintAmount);
                await KreskoAsset.rebase(hre.toBig(denominator), positive);

                expect(await KreskoAsset.balanceOf(hre.addr.deployer)).to.equal(defaultMintAmount.mul(denominator));
                expect(await KreskoAsset.totalSupply()).to.equal(defaultMintAmount.mul(denominator));
            });

            it("reduces balance and supply with negative rebase @ 2", async function () {
                const denominator = 2;
                const positive = false;
                await KreskoAsset.mint(hre.addr.deployer, defaultMintAmount);
                await KreskoAsset.rebase(hre.toBig(denominator), positive);

                expect(await KreskoAsset.balanceOf(hre.addr.deployer)).to.equal(defaultMintAmount.div(denominator));
                expect(await KreskoAsset.totalSupply()).to.equal(defaultMintAmount.div(denominator));
            });

            it("reduces balance and supply with negative rebase @ 3", async function () {
                const denominator = 3;
                const positive = false;
                await KreskoAsset.mint(hre.addr.deployer, defaultMintAmount);
                await KreskoAsset.rebase(hre.toBig(denominator), positive);

                expect(await KreskoAsset.balanceOf(hre.addr.deployer)).to.equal(defaultMintAmount.div(denominator));
                expect(await KreskoAsset.totalSupply()).to.equal(defaultMintAmount.div(denominator));
            });

            it("reduces balance and supply with negative rebase @ 100", async function () {
                const denominator = 100;
                const positive = false;
                await KreskoAsset.mint(hre.addr.deployer, defaultMintAmount);
                await KreskoAsset.rebase(hre.toBig(denominator), positive);

                expect(await KreskoAsset.balanceOf(hre.addr.deployer)).to.equal(defaultMintAmount.div(denominator));
                expect(await KreskoAsset.totalSupply()).to.equal(defaultMintAmount.div(denominator));
            });
        });

        describe("#transfer", () => {
            it("has default transfer behaviour after positive rebase", async function () {
                const transferAmount = hre.toBig(1);

                await KreskoAsset.mint(hre.addr.deployer, defaultMintAmount);
                await KreskoAsset.mint(hre.addr.userOne, defaultMintAmount);

                const denominator = 2;
                const positive = true;
                await KreskoAsset.rebase(hre.toBig(denominator), positive);

                const rebaseInfodDefaultMintAMount = defaultMintAmount.mul(denominator);

                await KreskoAsset.transfer(hre.addr.userOne, transferAmount);

                expect(await KreskoAsset.balanceOf(hre.addr.userOne)).to.equal(
                    rebaseInfodDefaultMintAMount.add(transferAmount),
                );
                expect(await KreskoAsset.balanceOf(hre.addr.deployer)).to.equal(
                    rebaseInfodDefaultMintAMount.sub(transferAmount),
                );
            });

            it("has default transfer behaviour after negative rebase", async function () {
                const transferAmount = hre.toBig(1);

                await KreskoAsset.mint(hre.addr.deployer, defaultMintAmount);
                await KreskoAsset.mint(hre.addr.userOne, defaultMintAmount);

                const denominator = 2;
                const positive = false;
                await KreskoAsset.rebase(hre.toBig(denominator), positive);

                const rebaseInfodDefaultMintAMount = defaultMintAmount.div(denominator);

                await KreskoAsset.transfer(hre.addr.userOne, transferAmount);

                expect(await KreskoAsset.balanceOf(hre.addr.userOne)).to.equal(
                    rebaseInfodDefaultMintAMount.add(transferAmount),
                );
                expect(await KreskoAsset.balanceOf(hre.addr.deployer)).to.equal(
                    rebaseInfodDefaultMintAMount.sub(transferAmount),
                );
            });

            it("has default transferFrom behaviour after positive rebase", async function () {
                const transferAmount = hre.toBig(1);

                await KreskoAsset.mint(hre.addr.deployer, defaultMintAmount);
                await KreskoAsset.mint(hre.addr.userOne, defaultMintAmount);

                const denominator = 2;
                const positive = true;
                await KreskoAsset.rebase(hre.toBig(denominator), positive);

                await KreskoAsset.approve(hre.addr.userOne, transferAmount);

                const rebaseInfodDefaultMintAMount = defaultMintAmount.mul(denominator);

                await KreskoAsset.connect(hre.users.userOne).transferFrom(
                    hre.addr.deployer,
                    hre.addr.userOne,
                    transferAmount,
                );

                expect(await KreskoAsset.balanceOf(hre.addr.userOne)).to.equal(
                    rebaseInfodDefaultMintAMount.add(transferAmount),
                );
                expect(await KreskoAsset.balanceOf(hre.addr.deployer)).to.equal(
                    rebaseInfodDefaultMintAMount.sub(transferAmount),
                );

                await expect(
                    KreskoAsset.connect(hre.users.userOne).transferFrom(
                        hre.addr.deployer,
                        hre.addr.userOne,
                        transferAmount,
                    ),
                ).to.be.revertedWith(Error.NOT_ENOUGH_ALLOWANCE);

                expect(await KreskoAsset.allowance(hre.addr.deployer, hre.addr.userOne)).to.equal(0);
            });

            it("has default transferFrom behaviour after positive rebase @ 100", async function () {
                const transferAmount = hre.toBig(1);

                await KreskoAsset.mint(hre.addr.deployer, defaultMintAmount);
                await KreskoAsset.mint(hre.addr.userOne, defaultMintAmount);

                const denominator = 100;
                const positive = true;
                await KreskoAsset.rebase(hre.toBig(denominator), positive);

                await KreskoAsset.approve(hre.addr.userOne, transferAmount);

                const rebaseInfodDefaultMintAMount = defaultMintAmount.mul(denominator);

                await KreskoAsset.connect(hre.users.userOne).transferFrom(
                    hre.addr.deployer,
                    hre.addr.userOne,
                    transferAmount,
                );

                expect(await KreskoAsset.balanceOf(hre.addr.userOne)).to.equal(
                    rebaseInfodDefaultMintAMount.add(transferAmount),
                );
                expect(await KreskoAsset.balanceOf(hre.addr.deployer)).to.equal(
                    rebaseInfodDefaultMintAMount.sub(transferAmount),
                );

                await expect(
                    KreskoAsset.connect(hre.users.userOne).transferFrom(
                        hre.addr.deployer,
                        hre.addr.userOne,
                        transferAmount,
                    ),
                ).to.be.revertedWith(Error.NOT_ENOUGH_ALLOWANCE);

                expect(await KreskoAsset.allowance(hre.addr.deployer, hre.addr.userOne)).to.equal(0);
            });

            it("has default transferFrom behaviour after negative rebase", async function () {
                const transferAmount = hre.toBig(1);

                await KreskoAsset.mint(hre.addr.deployer, defaultMintAmount);
                await KreskoAsset.mint(hre.addr.userOne, defaultMintAmount);

                const denominator = 2;
                const positive = false;
                await KreskoAsset.rebase(hre.toBig(denominator), positive);

                await KreskoAsset.approve(hre.addr.userOne, transferAmount);

                const rebaseInfodDefaultMintAMount = defaultMintAmount.div(denominator);

                await KreskoAsset.connect(hre.users.userOne).transferFrom(
                    hre.addr.deployer,
                    hre.addr.userOne,
                    transferAmount,
                );

                expect(await KreskoAsset.balanceOf(hre.addr.userOne)).to.equal(
                    rebaseInfodDefaultMintAMount.add(transferAmount),
                );
                expect(await KreskoAsset.balanceOf(hre.addr.deployer)).to.equal(
                    rebaseInfodDefaultMintAMount.sub(transferAmount),
                );

                await expect(
                    KreskoAsset.connect(hre.users.userOne).transferFrom(
                        hre.addr.deployer,
                        hre.addr.userOne,
                        transferAmount,
                    ),
                ).to.be.revertedWith(Error.NOT_ENOUGH_ALLOWANCE);

                expect(await KreskoAsset.allowance(hre.addr.deployer, hre.addr.userOne)).to.equal(0);
            });

            it("has default transferFrom behaviour after negative rebase @ 100", async function () {
                const transferAmount = hre.toBig(1);

                await KreskoAsset.mint(hre.addr.deployer, defaultMintAmount);
                await KreskoAsset.mint(hre.addr.userOne, defaultMintAmount);

                const denominator = 100;
                const positive = false;
                await KreskoAsset.rebase(hre.toBig(denominator), positive);

                await KreskoAsset.approve(hre.addr.userOne, transferAmount);

                const rebaseInfodDefaultMintAMount = defaultMintAmount.div(denominator);

                await KreskoAsset.connect(hre.users.userOne).transferFrom(
                    hre.addr.deployer,
                    hre.addr.userOne,
                    transferAmount,
                );

                expect(await KreskoAsset.balanceOf(hre.addr.userOne)).to.equal(
                    rebaseInfodDefaultMintAMount.add(transferAmount),
                );
                expect(await KreskoAsset.balanceOf(hre.addr.deployer)).to.equal(
                    rebaseInfodDefaultMintAMount.sub(transferAmount),
                );

                await expect(
                    KreskoAsset.connect(hre.users.userOne).transferFrom(
                        hre.addr.deployer,
                        hre.addr.userOne,
                        transferAmount,
                    ),
                ).to.be.revertedWith(Error.NOT_ENOUGH_ALLOWANCE);

                expect(await KreskoAsset.allowance(hre.addr.deployer, hre.addr.userOne)).to.equal(0);
            });
        });
    });
});

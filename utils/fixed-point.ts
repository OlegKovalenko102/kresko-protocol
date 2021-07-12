import { BigNumber } from "ethers"

// In other words, the raw value of 1e18 is equal to a FixedPoint of 1
const FIXED_POINT_SCALING_FACTOR = BigNumber.from(10).pow(18);

export function toFixedPoint(num: any) {
	// BigNumber enforces integer division - to allow a number with a few decimals to
	// be passed to this function (like 0.5), it's multiplied by 1000 and then subsequently
	// divided by 1000.
	return BigNumber.from(FIXED_POINT_SCALING_FACTOR).mul(1000 * num).div(1000);
}

export function fromFixedPoint(fixedPoint: any) {
	return BigNumber.from(fixedPoint).div(FIXED_POINT_SCALING_FACTOR);
}

// Multiplies two fixed point numbers together
export function fixedPointMul(a: BigNumber, b: any) {
	return a.mul(b).div(FIXED_POINT_SCALING_FACTOR)
}
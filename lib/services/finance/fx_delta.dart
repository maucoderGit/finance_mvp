/// Arbitrage differential between the official (BCV) and market (P2P)
/// VES→USD rates for a signed VES transaction amount.
///
/// Both rates are expressed as "1 USD = N VES". Returns USDT-lived value:
/// - VES expense (negative [amountVes]) → positive Gap Savings: the VES was
///   funded from USDT reserves, so spending at the official rate costs less
///   than its market replacement value.
/// - VES income (positive [amountVes]) → negative Replacement Loss: VES
///   received at the official rate is worth less when converted back to USDT
///   at the market rate.
double fxDeltaUsdt({
  required double amountVes,
  required double bcvRate,
  required double marketRate,
}) {
  if (amountVes == 0 || bcvRate <= 0 || marketRate <= 0) return 0;
  return -amountVes * (1 / bcvRate - 1 / marketRate);
}
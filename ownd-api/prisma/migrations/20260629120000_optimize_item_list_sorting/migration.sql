CREATE INDEX "Item_userId_isVirtual_nextBillingDate_idx"
  ON "Item"("userId", "isVirtual", "nextBillingDate");

CREATE INDEX "Item_userId_isScrapped_purchaseDate_idx"
  ON "Item"("userId", "isScrapped", "purchaseDate");

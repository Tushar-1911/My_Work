source(output(
		visitorId as string,
		topProductPurchases as (productId as string, itemsPurchasedLast12Months as string)[]
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	documentForm: 'arrayOfDocuments',
	wildcardPaths:['online-user-profiles-02/*.json']) ~> EcommerceUserProfiles
source(output(
		cartId as string,
		preferredProducts as integer[],
		productReviews as (productId as integer, reviewDate as string, reviewText as string)[],
		userId as integer
	),
	allowSchemaDrift: true,
	validateSchema: false,
	format: 'document') ~> UserProfiles
EcommerceUserProfiles derive(visitorId = toInteger(visitorId)) ~> userId
userId foldDown(unroll(topProductPurchases),
	mapColumn(
		visitorId,
		productId = topProductPurchases.productId,
		itemsPurchasedLast12Months = topProductPurchases.itemsPurchasedLast12Months
	),
	skipDuplicateMapInputs: false,
	skipDuplicateMapOutputs: false) ~> UserTopProducts
UserTopProducts derive(productId = toInteger(productId),
		itemsPurchasedLast12Months = toInteger(itemsPurchasedLast12Months)) ~> DerivedProductColumns
UserProfiles foldDown(unroll(preferredProducts),
	mapColumn(
		preferredProductId = preferredProducts,
		userId
	),
	skipDuplicateMapInputs: false,
	skipDuplicateMapOutputs: false) ~> UserPreferredProducts
DerivedProductColumns, UserPreferredProducts join(visitorId == userId,
	joinType:'outer',
	matchType:'exact',
	ignoreSpaces: false,
	partitionBy('hash', 30,
		productId
	),
	broadcast: 'left')~> JoinTopProductsWithPreferredProducts
JoinTopProductsWithPreferredProducts derive(isTopProduct = toBoolean(iif(isNull(productId), 'false', 'true')),
		isPreferredProduct = toBoolean(iif(isNull(preferredProductId), 'false', 'true')),
		productId = iif(isNull(productId), preferredProductId, productId),
		userId = iif(isNull(userId), visitorId, userId)) ~> DerivedColumnsForMerge
DerivedColumnsForMerge filter(!isNull(productId)) ~> Filter1
Filter1 sink(allowSchemaDrift: true,
	validateSchema: false,
	format: 'delta',
	compressionType: 'snappy',
	compressionLevel: 'Fastest',
	fileSystem: 'wwi-02',
	folderPath: 'top-products',
	truncate:true,
	mergeSchema: false,
	autoCompact: false,
	optimizedWrite: false,
	vacuum: 0,
	deletable:false,
	insertable:true,
	updateable:false,
	upsertable:false,
	umask: 0022,
	preCommands: [],
	postCommands: [],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	mapColumn(
		visitorId,
		productId,
		itemsPurchasedLast12Months,
		preferredProductId,
		userId,
		isTopProduct,
		isPreferredProduct
	)) ~> DataLake
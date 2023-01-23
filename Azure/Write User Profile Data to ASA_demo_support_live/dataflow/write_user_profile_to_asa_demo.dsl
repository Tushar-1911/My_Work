source(output(
		visitorId as integer,
		topProductPurchases as (productId as integer, itemsPurchasedLast12Months as integer)[]
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
		itemsPurchasedLast12Months = toInteger(itemsPurchasedLast12Months)) ~> DeriveProductColumns
UserProfiles foldDown(unroll(preferredProducts),
	mapColumn(
		preferredProducts,
		userId
	),
	skipDuplicateMapInputs: false,
	skipDuplicateMapOutputs: false) ~> UserPreferredProducts
DeriveProductColumns, UserPreferredProducts join(visitorId == userId,
	joinType:'outer',
	matchType:'exact',
	ignoreSpaces: false,
	partitionBy('hash', 30,
		productId
	),
	broadcast: 'left')~> JoinTopProductsWithPreferredProducts
JoinTopProductsWithPreferredProducts derive(isTopProduct = toBoolean(iif(isNull(productId), 'false', 'true')),
		isPreferredProduct = toBoolean(iif(isNull(preferredProducts), 'false', 'true')),
		productId = iif(isNull(productId), preferredProducts, productId),
		userId = iif(isNull(userId), visitorId, userId)) ~> DerivedColumnsForMerge
DerivedColumnsForMerge filter(!isNull(productId)) ~> Filter
Filter sink(allowSchemaDrift: true,
	validateSchema: false,
	input(
		UserId as integer,
		ProductId as integer,
		ItemsPurchasedLast12Months as integer,
		IsTopProduct as boolean,
		IsPreferredProduct as boolean
	),
	deletable:false,
	insertable:true,
	updateable:false,
	upsertable:false,
	truncate:true,
	format: 'table',
	staged: true,
	allowCopyCommand: true,
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	errorHandlingOption: 'stopOnFirstError',
	mapColumn(
		UserId = userId,
		ItemsPurchasedLast12Months = itemsPurchasedLast12Months,
		IsTopProduct = isTopProduct,
		IsPreferredProduct = isPreferredProduct
	)) ~> UserTopProductPurchasesASA
Filter sink(allowSchemaDrift: true,
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
		preferredProducts,
		userId,
		isTopProduct,
		isPreferredProduct
	)) ~> DataLake
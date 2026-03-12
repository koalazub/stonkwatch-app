import Foundation
import SwiftData

@Model
final class Stock {
    @Attribute(.unique) var ticker: String
    var name: String
    var exchange: String
    var isFollowed: Bool
    var lastPrice: Double?
    var priceChangePercent: Double?
    var updatedAt: Date

    init(
        ticker: String,
        name: String,
        exchange: String = "",
        isFollowed: Bool = false,
        lastPrice: Double? = nil,
        priceChangePercent: Double? = nil,
        updatedAt: Date = .now
    ) {
        self.ticker = ticker
        self.name = name
        self.exchange = exchange
        self.isFollowed = isFollowed
        self.lastPrice = lastPrice
        self.priceChangePercent = priceChangePercent
        self.updatedAt = updatedAt
    }
}

extension Stock {
    static func mock(
        ticker: String = "AAPL",
        name: String = "Apple Inc.",
        lastPrice: Double = 198.50,
        priceChangePercent: Double = 1.23
    ) -> Stock {
        Stock(
            ticker: ticker,
            name: name,
            exchange: "NASDAQ",
            isFollowed: true,
            lastPrice: lastPrice,
            priceChangePercent: priceChangePercent
        )
    }
}

--
-- MoneyMoney Web Banking extension
-- http://moneymoney-app.com/api/webbanking
--
--
-- The MIT License (MIT)
--
-- Copyright (c) Silsha Fux
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
--
-- Get balance for fairr.de
--

WebBanking {
    version     = 1.00,
    country     = "de",
    url         = "https://login.fairr.de",
    services    = {"fairr.de"},
    description = string.format(MM.localizeText("Get balance for %s"), "fairr.de")
}

function SupportsBank (protocol, bankCode)
    return bankCode == "fairr.de" and protocol == ProtocolWebBanking
end

function InitializeSession (protocol, bankCode, username, username2, password, username3)
    connection = Connection()
    connection.language = "de-de"

    local response = HTML(connection:get(url))
    response:xpath("//*[@id='zugangsNummer']"):attr("value", username)
    response:xpath("//*[@id='kennwort']"):attr("value", password)
    connection:request(response:xpath("//*[@id='loginForm']/button"):click())

    if string.match(connection:getBaseURL(), 'kunde.html') then
        return LoginFailed
    end
end

function ListAccounts (knownAccounts)
    local accounts = {}
    local response = HTML(connection:get(url .. "/vertrag.html?act=vertraege"))
    response:xpath("/html/body/div[2]/div[2]/div[2]/div/div/table/tbody/tr"):each(function (index, row)
        local accNrStr = {}
        for w in string.gmatch(row:xpath("td[2]/a"):attr("href"), "%d+") do
            table.insert(accNrStr, w)
        end

        local account = {
            name = row:xpath("td[1]/a"):text(),
            owner = "owner",
            accountNumber = accNrStr[1],
            currency = "EUR",
            type = AccountTypePortfolio,
            portfolio = true
        }

        table.insert(accounts, account)

    end)

    print("ListAccounts successful.")
    return accounts
end

function RefreshAccount (account, since)
    local transactions = {}
    local response = HTML(connection:get(url .. "/vertrag.html?act=uebersicht&vertragsId=" .. account.accountNumber))

    response:xpath("/html/body/div[2]/div[2]/div[2]/div[1]/div/table/tbody/tr"):each(function (index, row)
        if index == 1 then
            local transaction = {
                name = row:xpath("td[1]"):text(),
                market = "Fairr",
                currency = "EUR",
                amount = tonumber((row:xpath("td[2]"):text():gsub(",", "."))),
            }
            table.insert(transactions, transaction)
            return
        end

        local transaction = {
            name = row:xpath("td[1]/a"):text(),
            market = "Fairr",
            currency = nil,
            quantity = tonumber((row:xpath("td[3]"):text():gsub(",", "."))),
            amount = tonumber((row:xpath("td[6]"):text():gsub(",", "."))) + tonumber((row:xpath("td[7]"):text():gsub(",", "."))),
            price = tonumber((row:xpath("td[4]"):text():gsub("EUR", ""):gsub(",", ".")))
        }
        table.insert(transactions, transaction)

    end)

    return {securities = transactions}
end

function EndSession ()
    connection:get(url .. "/kunde.html?logout=1")

    print("Logout successful.")
end

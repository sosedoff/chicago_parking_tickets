require "faraday"
require "nokogiri"

class ParkingTickets
  BASE_URL = "https://parkingtickets.cityofchicago.org/CPSWeb/retrieveTicketsByLicensePlate.do"

  def fetch(plate, name, state = "IL", type = "PAS")
    resp = Faraday.get(BASE_URL, {
      plateNumber:    plate,
      plateState:     state,
      plateType:      type,
      plateOwnerName: name
    })

    extract_tickets_from_html(resp.body)
  end

  def fetch_unpaid(*args)
    fetch(*args).select { |t| t[:amount] != "$0.00" }
  end

  private

  def extract_tickets_from_html(text)
    doc = Nokogiri::HTML(text)
    doc.css("table.ticketList tbody tr").map { |row| parse_line_item(row.css("td")) }
  end

  def parse_line_item(cols)
    {
      number:    cols[1].text.strip,
      violation: cols[2].text.strip,
      plate:     cols[3].text.strip,
      state:     cols[4].text.strip,
      date:      cols[5].text.strip,
      amount:    cols[6].text.strip,
      status:    cols[7].css("a.Link")[0].attributes["title"].text.strip
    }
  end
end
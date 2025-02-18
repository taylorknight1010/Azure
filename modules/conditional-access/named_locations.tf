# Named Location Policy for Blacklisted Countries

resource "azuread_named_location" "blacklisted_countries" {
  display_name = "Blacklisted Countries"

  country {
    countries_and_regions = var.blacklisted_countries  # ISO 3166-1 alpha-2 country codes for China and Russia
    include_unknown_countries_and_regions = false
  }
}

resource "azuread_named_location" "customerName" {
  display_name = "customerName Trusted IPs"

  ip {
    ip_ranges = [
      "x.x.x.x/32",
      "x.x.x.x/32",
    ]
    trusted = true
  }
}

resource "azuread_named_location" "customer" {
  display_name = "${var.CustomerName} Trusted IPs"

  ip {
    ip_ranges = var.CustomerIpTrustedRange
    trusted = true
  }
}

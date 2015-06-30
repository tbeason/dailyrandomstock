# Daily Random Stock
There are thousands of publicly traded companies in the US. Most investors concentrate their efforts on the well-known stocks - don't be like them! There may be better investment opportunities in companies you have never heard of before. I created Daily Random Stock to showcase 1 of the over 3,000 companies on the biggest US exchanges each day. No media bias here! It may take a few seconds to load up.

This is a fully automatic interactive program that uses R Markdown, Shiny, and several useful R packages to display information from Quandl (and soon other sources) about a random stock. It is automatic because it will select a new stock and update on it's own each day.

### Twitter Authentication
To authenticate with Twitter, you will need to follow the instructions listed on the [twitteR package](https://github.com/geoffjentry/twitteR) vignette to find out your API Key and Access Token (and their corresponding Secrets). Once you have those, you need to put them in a CSV file named 'auths.csv' in this order:

1. consumer_key
2. consumer_secret
3. access_token
4. access_secret

auths.csv should only contain those 4 items, and it should be stored in the main directory of this program.

### Work in Progress
This program, while now fully functional, could still be improved. I would think of this as an Alpha release, with work still remaining on how to best store the data, minimize the number of function calls, speed up loading, and improve user experience.

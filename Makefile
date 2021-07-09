
install: index
	cp -v *.* docs

index:
	@echo "<!DOCTYPE html>" > index.html
	@echo "<html>" >> index.html
	@echo "<head>" >> index.html
	@echo "  <title>DokuWiki over I2P with Docker</title>" >> index.html
	@echo "  <link rel=\"stylesheet\" type=\"text/css\" href=\"home.css\" />" >> index.html
	@echo "</head>" >> index.html
	@echo "<body>" >> index.html
	pandoc README.md >> index.html
	@echo "</body>" >> index.html
	@echo "</html>" >> index.html


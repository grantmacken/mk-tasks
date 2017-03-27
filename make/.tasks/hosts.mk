hostsRemote:
	@cat /etc/hosts | grep $(NAME) >/dev/null || \
 echo '$(shell dig @8.8.8.8 +short $(NAME))  $(NAME)' >> /etc/hosts
	@sed -i "/$(NAME)/ s/.*/$(shell dig @8.8.8.8 +short $(NAME))\t$(NAME)/g" /etc/hosts
	@cat /etc/hosts | grep -oP '([0-9]{1,3}\.){3}[0-9]{1,3}\s+\S+'
	nmap $(shell dig @8.8.8.8 +short $(NAME))

# @curl -L -s -o /dev/null -w\
# "\n\tHTTP CODE:\t%{http_code}\n\tHTTP_VERSION:\t%{http_version}\n\tREMOTE_IP:\t%{remote_ip}\n\tLOCAL_IP:\t%{local_ip}\n"\
# http://$(NAME)
# @curl -L -s -o /dev/null -w "\n\tSSL VERIFY RESULT:\t%{ssl_verify_result}\n" https://$(NAME)
# @w3m -dump $(NAME)

hostsLocal:
	@cat /etc/hosts | grep $(NAME) >/dev/null || echo '127.0.0.1  $(NAME)' >> /etc/hosts
	@sed -i "/$(NAME)/ s/.*/127.0.0.1\t$(NAME)/g" /etc/hosts
	@cat /etc/hosts | grep -oP '([0-9]{1,3}\.){3}[0-9]{1,3}\s+\S+'
	@nmap $(NAME)
	@curl -L -s -o /dev/null -w\
 "\n\tHTTP CODE:\t%{http_code}\n\tHTTP_VERSION:\t%{http_version}\n\tREMOTE_IP:\t%{remote_ip}\n\tLOCAL_IP:\t%{local_ip}\n"\
  http://$(NAME)
	@w3m -dump $(NAME)
	@w3m -dump https://$(NAME)

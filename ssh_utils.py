import pexpect
import time

_sessions = {}  # store active sessions


def ssh_sudo_session(host, user, port, key_path, sudo_pass, retries=3):
    attempt = 0
    last_exception = None

    while attempt < retries:
        try:
            ssh_cmd = (
                f"ssh -oHostKeyAlgorithms=+ssh-rsa "
                f"-oPubkeyAcceptedKeyTypes=+ssh-rsa "
                f"-i {key_path} -p {port} {user}@{host}"
            )

            child = pexpect.spawn(ssh_cmd, encoding='utf-8', timeout=20)

            child.expect(['\\$ ', '# ', pexpect.EOF, pexpect.TIMEOUT])

            child.sendline('sudo su -')
            child.expect('Password:')
            child.sendline(sudo_pass)
            child.expect('# ')

            # create session id
            session_id = f"session_{int(time.time() * 1000)}"

            _sessions[session_id] = child

            return session_id

        except Exception as e:
            last_exception = e
            attempt += 1
            time.sleep(2)

    raise Exception(f"SSH connection failed after {retries} attempts: {last_exception}")


def send_command(session_id, command):
    child = _sessions.get(session_id)

    if not child:
        raise Exception(f"Invalid session id: {session_id}")

    child.sendline(command)
    child.expect('# ')

    output = child.before.strip().split('\r\n', 1)[-1]
    return output


def cli_output_parser(output, delimiter="=", mode="dict"):
    if mode == "dict":
        result = {}
        for line in output.splitlines():
            if delimiter in line:
                key, value = line.split(delimiter, 1)
                result[key.strip()] = value.strip()
        return result

    elif mode == "list":
        result = []
        for line in output.splitlines():
            clean_line = line.strip()
            if clean_line:
                result.append(clean_line)
        return result

    else:
        raise ValueError("mode must be 'dict' or 'list'")


def close_session(session_id):
    child = _sessions.pop(session_id, None)
    if child:
        child.close()
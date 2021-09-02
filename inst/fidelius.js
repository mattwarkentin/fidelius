document.addEventListener('DOMContentLoaded', function () {
  let nonce = sodium.from_hex(document.querySelector('#nonce').innerText)
  let encrypted = sodium.from_hex(
    document.querySelector('#encrypted').innerText,
  )

  let submit = document.querySelector('.fidelius__content__btn')
  let input = document.querySelector('.fidelius__content__input')

  const decrypter = () => {
    // Get the password and hash it
    let password = input.value
    let password_hash = sodium.crypto_hash_sha256(password)

    try {
      // Try the password and catch the error to throw "incorrect pass"
      let html = sodium.crypto_secretbox_open_easy(
        encrypted,
        nonce,
        password_hash,
      )
      let html_text = sodium.to_string(html)
      document.write(html_text)
      document.close()
    } catch (error) {
      // change to show incorrect pass
      input.select()
      input.focus()
    }
  }

  submit.addEventListener('click', decrypter)

  document.addEventListener('keyup', (e) => {
    if (e.keyCode === 13) {
      decrypter()
    }
  })
})

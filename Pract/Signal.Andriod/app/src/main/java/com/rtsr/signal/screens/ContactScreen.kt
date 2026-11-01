package com.rtsr.signal.screens

import android.net.Uri
import android.os.Build
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.BasicText
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withLink
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.rtsr.signal.R

@Composable
fun ContactScreen(){
    val gitUri = "https://github.com/Skverno-Slov"
    val email = "zaharlukanin19@gmail.com"

    val deviceModel = "${Build.MANUFACTURER} ${Build.MODEL}"
    val androidVersion = Build.VERSION.RELEASE

    val subject = stringResource(R.string.mail_subject)
    val emailBodyTemplate = stringResource(R.string.mail_body, deviceModel, androidVersion).trimIndent()

    val encodedSubject = Uri.encode(subject)
    val encodedBody = Uri.encode(emailBodyTemplate)
    val mailtoUrl = "mailto:$email?subject=$encodedSubject&body=$encodedBody"

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = stringResource(R.string.str_title_contact),
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(bottom = 32.dp, top = 16.dp)
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp))
        {
            Text(
                text = "github",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )

            LinkedText(gitUri, stringResource(R.string.str_open_web))

        }

        Spacer(modifier = Modifier.height(16.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp))
        {
            Text(
                text = "E-mail",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            LinkedText(mailtoUrl, stringResource(R.string.str_write_mail))
        }
    }
}

@Composable
fun LinkedText(dynamicUrl: String, linkLabel: String) {
    val annotatedString = buildAnnotatedString {
        withLink(
            LinkAnnotation.Url(
                url = dynamicUrl,
                styles = TextLinkStyles(
                    style = SpanStyle(
                        color = MaterialTheme.colorScheme.primary,
                        textDecoration = TextDecoration.Underline
                    )
                )
            )
        ) {
            append(linkLabel)
        }

    }

    BasicText(text = annotatedString, style = MaterialTheme.typography.titleMedium)
}
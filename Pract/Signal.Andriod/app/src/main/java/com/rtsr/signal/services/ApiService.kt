package com.rtsr.signal.services

import com.rtsr.signal.dtos.EquipmentDto
import com.rtsr.signal.dtos.GraphPointDto
import com.rtsr.signal.dtos.LatestReadingResponse
import com.rtsr.signal.dtos.LoginRequest
import com.rtsr.signal.dtos.PagedLogsDto
import com.rtsr.signal.dtos.PingResponse
import com.rtsr.signal.dtos.ReadingLogDto
import com.rtsr.signal.dtos.RefreshRequest
import com.rtsr.signal.dtos.TokenResponse
import com.rtsr.signal.models.MainUiState
import okhttp3.Authenticator
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.Response
import okhttp3.internal.tls.OkHostnameVerifier.verify
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query
import retrofit2.http.Url
import javax.net.ssl.HostnameVerifier

interface ApiService {
    @POST("api/auth/login")
    suspend fun login(
        @Body request: LoginRequest,
        @Header("X-Device-Name") deviceName: String
    ): TokenResponse

    @POST("api/auth/refresh")
    fun refreshTokens(@Body request: RefreshRequest): retrofit2.Call<TokenResponse>

    @POST("api/auth/refresh")
    suspend fun refreshTokensAsync(@Body request: RefreshRequest): TokenResponse

    @POST("api/auth/logout")
    suspend fun logoutServer(@Body request: RefreshRequest): Any

    @GET("api/equipment/{serialNumber}/logs")
    suspend fun getEquipmentLogs(
        @Path("serialNumber") serialNumber: String,
        @Query("period") period: String,
        @Query("identifier") identifier: String?,
        @Query("page") page: Int,
        @Query("pageSize") pageSize: Int
    ): PagedLogsDto

    @GET("api/equipment")
    suspend fun getEquipmentList(): List<EquipmentDto>

    @GET
    suspend fun checkApiHealth(@Url url: String): PingResponse

    @GET("api/equipment/{serialNumber}/graph")
    suspend fun getFullGraphData(
        @Path("serialNumber") serialNumber: String,
        @Query("period") period: String
    ): List<GraphPointDto>

    @GET("api/equipment/{serialNumber}/latest")
    suspend fun getLatestReadings(
        @Path("serialNumber") serialNumber: String
    ): List<LatestReadingResponse>
}

object NetworkClient {
    private var apiService: ApiService? = null

    fun init(uiState: MainUiState, tokenManager: TokenManager?) {
        val savedAddress = uiState.apiAddress
        val savedPort = uiState.apiPort
        val savedProtocol = uiState.useHttps
        val dynamicBaseUrl = "http$savedProtocol://$savedAddress:$savedPort/"

        val baseOkHttpClient = OkHttpClient
            .Builder()
            .build()

        val baseRetrofit = Retrofit.Builder()
            .baseUrl(dynamicBaseUrl)
            .client(baseOkHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()

        val authServiceForRefresh = baseRetrofit.create(ApiService::class.java)

        val authInterceptor = Interceptor { chain ->
            val requestBuilder = chain.request().newBuilder()
            tokenManager?.getAccessToken()?.let { token ->
                requestBuilder.addHeader("Authorization", "Bearer $token")
            }
            chain.proceed(requestBuilder.build())
        }

        val tokenAuthenticator = Authenticator { _, response ->
            if (response.request.url.encodedPath.contains("api/auth/login")) {
                return@Authenticator null
            }

            if (response.request.url.encodedPath.contains("api/auth/refresh")) {
                return@Authenticator null
            }

            if (response.responseCount > 1) {
                tokenManager?.clearTokens()
                return@Authenticator null
            }

            val refreshToken = tokenManager?.getRefreshToken() ?: return@Authenticator null

            synchronized(this) {
                try {
                    val refreshResponse = authServiceForRefresh.refreshTokens(RefreshRequest(refreshToken)).execute()

                    if (refreshResponse.isSuccessful && refreshResponse.body() != null) {
                        val newTokens = refreshResponse.body()!!
                        tokenManager.saveTokens(newTokens.accessToken, newTokens.refreshToken)

                        return@Authenticator response.request.newBuilder()
                            .header("Authorization", "Bearer ${newTokens.accessToken}")
                            .build()
                    } else {
                        tokenManager.clearTokens()
                        return@Authenticator null
                    }
                } catch (_: Exception) {
                    return@Authenticator null
                }
            }
        }

        val protectedOkHttpClient = OkHttpClient.Builder()
            .addInterceptor(authInterceptor)
            .authenticator(tokenAuthenticator)
            .build()

        val retrofit = Retrofit.Builder()
            .baseUrl(dynamicBaseUrl)
            .client(protectedOkHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()

        synchronized(this) {
            apiService = retrofit.create(ApiService::class.java)
        }
    }

    fun getApi(): ApiService {
        return apiService ?: synchronized(this) {
            apiService ?: throw UninitializedPropertyAccessException("NetworkClient не был инициализирован. Вызовите init() перед использованием.")
        }
    }
}

private val Response.responseCount: Int
    get() = generateSequence(this) { it.priorResponse }.count()